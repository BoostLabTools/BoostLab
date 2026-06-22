Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'services-optimizer'
    Title = 'Services Optimizer'
    Stage = 'Advanced'
    Order = 3
    Type = 'assistant'
    RiskLevel = 'high'
    Description = 'Stage the approved Ultimate Services Off or Services Default Safe Mode workflow.'
    Actions = @('Analyze', 'Apply', 'Default')
    Capabilities = [ordered]@{
        RequiresAdmin = $true
        RequiresInternet = $false
        CanReboot = $true
        CanModifyRegistry = $true
        CanModifyServices = $true
        CanInstallSoftware = $false
        CanDownload = $false
        CanModifyDrivers = $false
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
$script:BoostLabServicesOptimizerSourcePath = Join-Path $script:BoostLabProjectRoot 'source-ultimate\8 Advanced\5 Services Optimizer.ps1'
$script:BoostLabServicesOptimizerSourceHash = '386EEF403F48907E82C2E8E4BE5DFE509B0ED93CADBB5639B42D6326163EDB8F'
$script:BoostLabServicesOptimizerCanonicalSourceHash = '15E4E1EAE613C70F91B15DC2614C6EB7DB8A80ADA1618297188FB41A38F0F1AE'
$script:BoostLabServicesOptimizerServiceRoot = 'HKLM:\SYSTEM\ControlSet001\Services'
$script:BoostLabServicesOptimizerRestorePointCommands = @(
    'reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v "SystemRestorePointCreationFrequency" /t REG_DWORD /d "0" /f >nul 2>&1'
    'Enable-ComputerRestore -Drive "C:\"'
    'Checkpoint-Computer -Description "beforeservices" -RestorePointType "MODIFY_SETTINGS"'
    'reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v "SystemRestorePointCreationFrequency" /f >nul 2>&1'
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

function Get-BoostLabServicesOptimizerPropertyValue {
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

function New-BoostLabServicesOptimizerResult {
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

function Get-BoostLabServicesOptimizerSourceInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string]$SourcePath = $script:BoostLabServicesOptimizerSourcePath
    )

    $sourceVerificationModulePath = Join-Path $script:BoostLabProjectRoot 'core\SourceVerification.psm1'
    if (-not (Get-Command -Name 'Test-BoostLabSourceChecksum' -ErrorAction SilentlyContinue)) {
        Import-Module -Name $sourceVerificationModulePath -Scope Local -Force -ErrorAction Stop
    }

    $verification = Test-BoostLabSourceChecksum -LiteralPath $SourcePath -ExpectedSha256 $script:BoostLabServicesOptimizerSourceHash -ExpectedCanonicalSha256 $script:BoostLabServicesOptimizerCanonicalSourceHash

    [pscustomobject]@{
        SourcePath = $SourcePath
        Exists = [bool]$verification.Exists
        ExpectedSha256 = $script:BoostLabServicesOptimizerSourceHash
        ActualSha256 = [string]$verification.DetectedSha256
        ExpectedCanonicalSha256 = $script:BoostLabServicesOptimizerCanonicalSourceHash
        ActualCanonicalSha256 = [string]$verification.DetectedCanonicalSha256
        HashMatches = [string]$verification.ChecksumStatus -eq 'Passed'
        ChecksumStatus = [string]$verification.ChecksumStatus
        VerificationMode = [string]$verification.VerificationMode
    }
}

function Assert-BoostLabServicesOptimizerSourceIdentity {
    param(
        [string]$SourcePath = $script:BoostLabServicesOptimizerSourcePath
    )

    $sourceInfo = Get-BoostLabServicesOptimizerSourceInfo -SourcePath $SourcePath
    if (-not $sourceInfo.Exists) {
        throw "Services Optimizer Ultimate source is missing: $SourcePath"
    }
    if (-not $sourceInfo.HashMatches) {
        throw "Services Optimizer Ultimate source hash mismatch. Expected $($sourceInfo.ExpectedSha256), detected $($sourceInfo.ActualSha256)."
    }
    return $sourceInfo
}

function Get-BoostLabServicesOptimizerSourceText {
    param(
        [string]$SourcePath = $script:BoostLabServicesOptimizerSourcePath
    )

    Assert-BoostLabServicesOptimizerSourceIdentity -SourcePath $SourcePath | Out-Null
    return Get-Content -Raw -LiteralPath $SourcePath
}

function Get-BoostLabServicesOptimizerBranchDefinition {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [string]$SourcePath = $script:BoostLabServicesOptimizerSourcePath
    )

    $source = Get-BoostLabServicesOptimizerSourceText -SourcePath $SourcePath
    $isApply = $ActionName -eq 'Apply'
    $variableName = if ($isApply) { 'ServicesOff' } else { 'ServicesOn' }
    $fileStem = if ($isApply) { 'servicesoff' } else { 'serviceson' }
    $label = if ($isApply) { 'Services: Off' } else { 'Services: Default' }
    $regex = [regex]::new(
        ('(?s)\${0}\s*=\s*@''\r?\n(?<Content>.*)\r?\n''@\r?\nSet-Content -Path "\$env:SystemRoot\\Temp\\{1}\.ps1"' -f $variableName, $fileStem),
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    $match = $regex.Match($source)
    if (-not $match.Success) {
        throw "Unable to extract the source-defined $label generated script."
    }

    $scriptContentBeforePatch = $match.Groups['Content'].Value
    $scriptContentAfterPatch = $scriptContentBeforePatch -replace "``'@", "'@"
    $serviceMatches = [regex]::Matches(
        $scriptContentAfterPatch,
        '\[HKEY_LOCAL_MACHINE\\SYSTEM\\ControlSet001\\Services\\(?<Name>[^\]]+)\]\s*\r?\n"Start"=dword:(?<Value>[0-9a-fA-F]{8})'
    )
    $serviceTargets = @(
        foreach ($serviceMatch in $serviceMatches) {
            [pscustomobject]@{
                Name = [string]$serviceMatch.Groups['Name'].Value
                StartValue = [Convert]::ToInt32($serviceMatch.Groups['Value'].Value, 16)
                RegistryPath = "HKLM:\SYSTEM\ControlSet001\Services\$($serviceMatch.Groups['Name'].Value)"
            }
        }
    )

    [pscustomobject]@{
        ActionName = $ActionName
        SourceLabel = $label
        VariableName = $variableName
        FileStem = $fileStem
        GeneratedScriptFileName = "$fileStem.ps1"
        GeneratedRegFileName = "$fileStem.reg"
        RunOnceValueName = "*$fileStem"
        RunOnceCommandSuffix = "Temp\$fileStem.ps1"
        ScriptContentBeforePatch = $scriptContentBeforePatch
        ScriptContentAfterPatch = $scriptContentAfterPatch
        ServiceTargets = $serviceTargets
        ServiceTargetCount = @($serviceTargets).Count
        UniqueServiceTargetCount = @($serviceTargets | ForEach-Object { $_.Name } | Sort-Object -Unique).Count
    }
}

function Get-BoostLabServicesOptimizerAnalyzeData {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string]$SourcePath = $script:BoostLabServicesOptimizerSourcePath
    )

    $sourceInfo = Get-BoostLabServicesOptimizerSourceInfo -SourcePath $SourcePath
    $applyBranch = if ($sourceInfo.HashMatches) {
        Get-BoostLabServicesOptimizerBranchDefinition -ActionName 'Apply' -SourcePath $SourcePath
    }
    else {
        $null
    }
    $defaultBranch = if ($sourceInfo.HashMatches) {
        Get-BoostLabServicesOptimizerBranchDefinition -ActionName 'Default' -SourcePath $SourcePath
    }
    else {
        $null
    }

    [pscustomobject]@{
        SourcePath = $sourceInfo.SourcePath
        SourceSha256 = $sourceInfo.ActualSha256
        SourceHashMatches = $sourceInfo.HashMatches
        Branches = @('Services: Off', 'Services: Default')
        ApplyBranch = if ($null -ne $applyBranch) {
            [pscustomobject]@{
                Label = $applyBranch.SourceLabel
                GeneratedScript = $applyBranch.GeneratedScriptFileName
                GeneratedRegFile = $applyBranch.GeneratedRegFileName
                RunOnceValueName = $applyBranch.RunOnceValueName
                ServiceTargetCount = $applyBranch.ServiceTargetCount
                UniqueServiceTargetCount = $applyBranch.UniqueServiceTargetCount
            }
        }
        else { $null }
        DefaultBranch = if ($null -ne $defaultBranch) {
            [pscustomobject]@{
                Label = $defaultBranch.SourceLabel
                GeneratedScript = $defaultBranch.GeneratedScriptFileName
                GeneratedRegFile = $defaultBranch.GeneratedRegFileName
                RunOnceValueName = $defaultBranch.RunOnceValueName
                ServiceTargetCount = $defaultBranch.ServiceTargetCount
                UniqueServiceTargetCount = $defaultBranch.UniqueServiceTargetCount
            }
        }
        else { $null }
        SourceWorkflow = @(
            'Attempt source-defined restore point prelude.'
            'Write the source-defined generated Safe Mode PowerShell script under %SystemRoot%\Temp.'
            'Patch the generated script here-string terminator exactly like Ultimate.'
            'Create the source-defined RunOnce value.'
            'Set bcdedit safeboot minimal.'
            'Restart Windows into Safe Mode.'
            'Generated script imports the source-defined REG payload as TrustedInstaller and Administrator.'
            'Generated script removes safeboot and restarts Windows again.'
        )
        RejectedRedesignBehavior = @(
            'No smart device analyzer.'
            'No Gaming, Performance, or Extreme profiles.'
            'No service recommendation engine.'
            'No compatibility scoring.'
            'No new backup/restore model.'
        )
        SupportsRestore = $false
        SupportsOpen = $false
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
        ActionLabels = [pscustomobject]@{
            Analyze = 'Analyze'
            Apply = 'Services: Off'
            Default = 'Services: Default'
        }
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string]$OperatingSystem = $env:OS,

        [string]$SystemRoot = $env:SystemRoot,

        [scriptblock]$CommandResolver = {
            param($CommandName)
            Get-Command -Name $CommandName -ErrorAction SilentlyContinue
        },

        [string]$SourcePath = $script:BoostLabServicesOptimizerSourcePath
    )

    $sourceInfo = Get-BoostLabServicesOptimizerSourceInfo -SourcePath $SourcePath
    $missingCommands = @(
        foreach ($commandName in @(
            'Enable-ComputerRestore'
            'Checkpoint-Computer'
            'bcdedit.exe'
            'shutdown.exe'
            'cmd.exe'
        )) {
            $resolved = @(& $CommandResolver $commandName)
            if ($resolved.Count -eq 0) {
                $commandName
            }
        }
    )
    $supported = (
        $OperatingSystem -eq 'Windows_NT' -and
        -not [string]::IsNullOrWhiteSpace($SystemRoot) -and
        $sourceInfo.HashMatches -and
        $missingCommands.Count -eq 0
    )

    [pscustomobject]@{
        Supported = $supported
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        SourceHashMatches = $sourceInfo.HashMatches
        MissingCommands = $missingCommands
        Reason = if ($OperatingSystem -ne 'Windows_NT') {
            'Services Optimizer requires Windows.'
        }
        elseif ([string]::IsNullOrWhiteSpace($SystemRoot)) {
            'Services Optimizer requires SystemRoot.'
        }
        elseif (-not $sourceInfo.HashMatches) {
            'Services Optimizer Ultimate source identity could not be verified.'
        }
        elseif ($missingCommands.Count -gt 0) {
            'Services Optimizer is unavailable because required commands were not found: {0}.' -f ($missingCommands -join ', ')
        }
        else {
            'The required Services Optimizer source identity and command surface are available.'
        }
        Timestamp = Get-Date
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceInfo = Get-BoostLabServicesOptimizerSourceInfo
    [pscustomobject]@{
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Status = if ($sourceInfo.HashMatches) { 'Source workflow available' } else { 'Source identity unavailable' }
        LastAction = $null
        LastResult = $null
        RestartRequired = $false
        Timestamp = Get-Date
    }
}

function Invoke-BoostLabServicesOptimizerCommand {
    param(
        [Parameter(Mandatory)]
        [string]$CommandText
    )

    $commandProcessorPath = Join-Path $env:SystemRoot 'System32\cmd.exe'
    $output = & $commandProcessorPath /d /c $CommandText 2>&1
    [pscustomobject]@{
        Success = ($LASTEXITCODE -eq 0)
        Output = (@($output) | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
    }
}

function Invoke-BoostLabServicesOptimizerRestorePointPrelude {
    param(
        [scriptblock]$CommandInvoker,

        [scriptblock]$PowerShellInvoker
    )

    $attempts = [System.Collections.Generic.List[object]]::new()
    try {
        $attempts.Add([pscustomobject]@{
            Step = 'SetRestorePointCreationFrequency'
            Result = & $CommandInvoker $script:BoostLabServicesOptimizerRestorePointCommands[0]
        })
        $attempts.Add([pscustomobject]@{
            Step = 'EnableComputerRestore'
            Result = & $PowerShellInvoker 'Enable-ComputerRestore'
        })
        $attempts.Add([pscustomobject]@{
            Step = 'CheckpointComputer'
            Result = & $PowerShellInvoker 'Checkpoint-Computer'
        })
        $attempts.Add([pscustomobject]@{
            Step = 'DeleteRestorePointCreationFrequency'
            Result = & $CommandInvoker $script:BoostLabServicesOptimizerRestorePointCommands[3]
        })
    }
    catch {
        $attempts.Add([pscustomobject]@{
            Step = 'RestorePointPreludeWarning'
            Result = [pscustomobject]@{ Success = $false; Output = $_.Exception.Message }
        })
    }

    return $attempts.ToArray()
}

function Invoke-BoostLabServicesOptimizerAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [scriptblock]$AdministratorChecker = { Test-BoostLabAdministrator },

        [scriptblock]$CommandInvoker = {
            param($CommandText)
            Invoke-BoostLabServicesOptimizerCommand -CommandText $CommandText
        },

        [scriptblock]$PowerShellInvoker = {
            param($CommandName)
            switch ($CommandName) {
                'Enable-ComputerRestore' {
                    Enable-ComputerRestore -Drive 'C:\' -ErrorAction SilentlyContinue | Out-Null
                    [pscustomobject]@{ Success = $true; Output = '' }
                }
                'Checkpoint-Computer' {
                    Checkpoint-Computer -Description 'beforeservices' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction SilentlyContinue | Out-Null
                    [pscustomobject]@{ Success = $true; Output = '' }
                }
            }
        },

        [scriptblock]$FileWriter = {
            param($Path, $Content)
            Set-Content -Path $Path -Value $Content -Force
            [pscustomobject]@{ Success = $true; Output = '' }
        },

        [scriptblock]$FilePatcher = {
            param($Path)
            (Get-Content $Path -Raw) -replace "``'@", "'@" | Set-Content $Path -NoNewline
            [pscustomobject]@{ Success = $true; Output = '' }
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

        [string]$SourcePath = $script:BoostLabServicesOptimizerSourcePath
    )

    if (-not [bool](& $AdministratorChecker)) {
        return New-BoostLabServicesOptimizerResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Administrator rights are required to stage the Services Optimizer Safe Mode workflow.'
    }
    if ([string]::IsNullOrWhiteSpace($SystemRoot)) {
        return New-BoostLabServicesOptimizerResult `
            -Success $false `
            -Action $ActionName `
            -Message 'SystemRoot is unavailable; Services Optimizer cannot stage the source-defined workflow.'
    }

    try {
        $sourceInfo = Assert-BoostLabServicesOptimizerSourceIdentity -SourcePath $SourcePath
        $branch = Get-BoostLabServicesOptimizerBranchDefinition -ActionName $ActionName -SourcePath $SourcePath
    }
    catch {
        return New-BoostLabServicesOptimizerResult `
            -Success $false `
            -Action $ActionName `
            -Message $_.Exception.Message
    }

    $tempRoot = Join-Path $SystemRoot 'Temp'
    $scriptPath = Join-Path $tempRoot $branch.GeneratedScriptFileName
    $runOnceCommand = 'reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "{0}" /t REG_SZ /d "powershell.exe -nop -ep bypass -WindowStyle Maximized -f {1}" /f >nul 2>&1' -f $branch.RunOnceValueName, $scriptPath
    $safeBootCommand = 'bcdedit /set {current} safeboot minimal >nul 2>&1'
    $operations = [System.Collections.Generic.List[object]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()

    $restorePointAttempts = Invoke-BoostLabServicesOptimizerRestorePointPrelude `
        -CommandInvoker $CommandInvoker `
        -PowerShellInvoker $PowerShellInvoker
    $operations.Add([pscustomobject]@{ Step = 'RestorePointPrelude'; Details = $restorePointAttempts })

    foreach ($step in @(
        [pscustomobject]@{
            Name = 'WriteGeneratedScript'
            Invoke = { & $FileWriter $scriptPath $branch.ScriptContentBeforePatch }
        }
        [pscustomobject]@{
            Name = 'PatchGeneratedScript'
            Invoke = { & $FilePatcher $scriptPath }
        }
        [pscustomobject]@{
            Name = 'InstallRunOnce'
            Invoke = { & $CommandInvoker $runOnceCommand }
        }
        [pscustomobject]@{
            Name = 'SetSafeBootMinimal'
            Invoke = { & $CommandInvoker $safeBootCommand }
        }
        [pscustomobject]@{
            Name = 'SleepBeforeRestart'
            Invoke = { & $SleepInvoker 5 }
        }
        [pscustomobject]@{
            Name = 'Restart'
            Invoke = { & $RestartInvoker }
        }
    )) {
        try {
            $result = & $step.Invoke
            $operations.Add([pscustomobject]@{ Step = $step.Name; Result = $result })
            if (-not [bool](Get-BoostLabServicesOptimizerPropertyValue -InputObject $result -Name 'Success' -DefaultValue $true)) {
                $errors.Add(("{0} failed: {1}" -f $step.Name, (Get-BoostLabServicesOptimizerPropertyValue -InputObject $result -Name 'Output' -DefaultValue 'Unknown failure')))
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
        GeneratedScriptPath = $scriptPath
        GeneratedScriptFileName = $branch.GeneratedScriptFileName
        GeneratedRegFileName = $branch.GeneratedRegFileName
        RunOnceValueName = $branch.RunOnceValueName
        RunOnceCommand = $runOnceCommand
        SafeBootCommand = $safeBootCommand
        ServiceTargetCount = $branch.ServiceTargetCount
        UniqueServiceTargetCount = $branch.UniqueServiceTargetCount
        Operations = $operations.ToArray()
        Errors = $errors.ToArray()
        RejectedRedesign = @(
            'No smart device analyzer.'
            'No Gaming, Performance, or Extreme profiles.'
            'No service recommendation engine.'
            'No compatibility scoring.'
            'No new backup/restore model.'
        )
        RestartSequence = 'Source-equivalent workflow restarts into Safe Mode, runs the generated script through RunOnce, imports the REG payload as TrustedInstaller and Administrator, removes safeboot, and restarts again.'
        CompletedAt = Get-Date
    }

    $success = $errors.Count -eq 0
    $message = if (-not $success) {
        "Services Optimizer $($branch.SourceLabel) staging failed: $($errors -join '; ')"
    }
    else {
        "Services Optimizer $($branch.SourceLabel) source workflow was staged; Windows restart was requested exactly as defined by Ultimate."
    }

    return New-BoostLabServicesOptimizerResult `
        -Success $success `
        -Action $ActionName `
        -Message $message `
        -Data $data
}

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ActionName,

        [bool]$Confirmed = $false
    )

    if ($ActionName -notin @($script:BoostLabImplementedActions)) {
        return New-BoostLabServicesOptimizerResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Unsupported action. Only Analyze, Apply, and Default are allowed.'
    }

    if ($ActionName -eq 'Analyze') {
        return New-BoostLabServicesOptimizerResult `
            -Success $true `
            -Action 'Analyze' `
            -Message 'Services Optimizer source workflow analyzed.' `
            -Data (Get-BoostLabServicesOptimizerAnalyzeData)
    }

    if (-not $Confirmed) {
        return New-BoostLabServicesOptimizerResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Cancelled by user' `
            -Cancelled $true
    }

    return Invoke-BoostLabServicesOptimizerAction -ActionName $ActionName
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
