Set-StrictMode -Version Latest

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'timer-resolution-assistant'
    Title = 'Timer Resolution Assistant'
    Stage = 'Advanced'
    Order = 4
    Type = 'assistant'
    RiskLevel = 'high'
    Description = 'Apply the approved Ultimate timer resolution service workflow or remove it with the source-defined Default branch.'
    Actions = @('Analyze', 'Apply', 'Default')
    Capabilities = [ordered]@{
        RequiresAdmin = $true
        RequiresInternet = $false
        CanReboot = $false
        CanModifyRegistry = $true
        CanModifyServices = $true
        CanInstallSoftware = $true
        CanDownload = $false
        CanModifyDrivers = $false
        CanModifySecurity = $false
        CanDeleteFiles = $true
        UsesTrustedInstaller = $false
        UsesSafeMode = $false
        SupportsDefault = $true
        SupportsRestore = $false
        NeedsExplicitConfirmation = $true
    }
}

$script:BoostLabImplementedActions = @('Analyze', 'Apply', 'Default')
$script:BoostLabProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$script:BoostLabTimerSourcePath = Join-Path $script:BoostLabProjectRoot 'source-ultimate\8 Advanced\6 Timer Resolution Assistant.ps1'
$script:BoostLabTimerSourceHash = '883F7CF4E6179383DE02E44B94FFC8DAFD380246751F1B1D81CAB8800B1E8621'
$script:BoostLabTimerServiceName = 'Set Timer Resolution Service'
$script:BoostLabTimerInternalServiceName = 'STR'
$script:BoostLabTimerCompilerPath = 'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe'
$script:BoostLabTimerCompilerArguments = '-out:C:\Windows\SetTimerResolutionService.exe C:\Windows\SetTimerResolutionService.cs'
$script:BoostLabTimerRegistryCommandPath = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
$script:BoostLabTimerRegistryDisplayPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel'
$script:BoostLabTimerRegistryValueName = 'GlobalTimerResolutionRequests'

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

function Get-BoostLabTimerPropertyValue {
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

function New-BoostLabTimerResolutionResult {
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
        RestartRequired = $false
        Cancelled = $Cancelled
        Timestamp = Get-Date
        Data = $Data
    }
}

function Get-BoostLabTimerSourceInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string]$SourcePath = $script:BoostLabTimerSourcePath
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
        ExpectedSha256 = $script:BoostLabTimerSourceHash
        ActualSha256 = $hash
        HashMatches = ($exists -and $hash -eq $script:BoostLabTimerSourceHash)
    }
}

function Assert-BoostLabTimerSourceIdentity {
    param(
        [string]$SourcePath = $script:BoostLabTimerSourcePath
    )

    $sourceInfo = Get-BoostLabTimerSourceInfo -SourcePath $SourcePath
    if (-not $sourceInfo.Exists) {
        throw "Timer Resolution Assistant Ultimate source is missing: $SourcePath"
    }
    if (-not $sourceInfo.HashMatches) {
        throw "Timer Resolution Assistant Ultimate source hash mismatch. Expected $($sourceInfo.ExpectedSha256), detected $($sourceInfo.ActualSha256)."
    }
    return $sourceInfo
}

function Get-BoostLabTimerSourceText {
    param(
        [string]$SourcePath = $script:BoostLabTimerSourcePath
    )

    Assert-BoostLabTimerSourceIdentity -SourcePath $SourcePath | Out-Null
    return Get-Content -Raw -LiteralPath $SourcePath
}

function Get-BoostLabTimerCSharpPayload {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$SourcePath = $script:BoostLabTimerSourcePath
    )

    $source = Get-BoostLabTimerSourceText -SourcePath $SourcePath
    $regex = [regex]::new(
        '(?s)\$csfile\s*=\s*@''\r?\n(?<Content>.*?)\r?\n''@\r?\nSet-Content -Path "\$env:SystemDrive\\Windows\\SetTimerResolutionService\.cs"',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    $match = $regex.Match($source)
    if (-not $match.Success) {
        throw 'Unable to extract the source-defined Timer Resolution C# payload.'
    }
    return [string]$match.Groups['Content'].Value
}

function Get-BoostLabTimerPaths {
    param(
        [string]$SystemDrive = $env:SystemDrive
    )

    $drive = if ([string]::IsNullOrWhiteSpace($SystemDrive)) { 'C:' } else { $SystemDrive.TrimEnd('\') }
    [pscustomobject]@{
        GeneratedSourcePath = Join-Path $drive 'Windows\SetTimerResolutionService.cs'
        GeneratedExecutablePath = Join-Path $drive 'Windows\SetTimerResolutionService.exe'
        CompilerPath = $script:BoostLabTimerCompilerPath
        CompilerArguments = $script:BoostLabTimerCompilerArguments
        SourceCompilerInputPath = 'C:\Windows\SetTimerResolutionService.cs'
        SourceCompilerOutputPath = 'C:\Windows\SetTimerResolutionService.exe'
    }
}

function Get-BoostLabTimerResolutionAnalyzeData {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string]$SourcePath = $script:BoostLabTimerSourcePath,

        [string]$SystemDrive = $env:SystemDrive
    )

    $sourceInfo = Get-BoostLabTimerSourceInfo -SourcePath $SourcePath
    $paths = Get-BoostLabTimerPaths -SystemDrive $SystemDrive
    $payload = if ($sourceInfo.HashMatches) {
        Get-BoostLabTimerCSharpPayload -SourcePath $SourcePath
    }
    else {
        ''
    }

    [pscustomobject]@{
        SourcePath = $sourceInfo.SourcePath
        SourceSha256 = $sourceInfo.ActualSha256
        SourceHashMatches = $sourceInfo.HashMatches
        Branches = @('Timer Resolution: On (Recommended)', 'Timer Resolution: Default')
        ApplyLabel = 'Timer Resolution: On (Recommended)'
        DefaultLabel = 'Timer Resolution: Default'
        ServiceName = $script:BoostLabTimerServiceName
        InternalServiceName = $script:BoostLabTimerInternalServiceName
        ServiceAccount = 'LocalSystem'
        GeneratedSourcePath = $paths.GeneratedSourcePath
        GeneratedExecutablePath = $paths.GeneratedExecutablePath
        CompilerPath = $paths.CompilerPath
        CompilerArguments = $paths.CompilerArguments
        RegistryPath = $script:BoostLabTimerRegistryDisplayPath
        RegistryValueName = $script:BoostLabTimerRegistryValueName
        RegistryApplyValue = 1
        RegistryDefaultState = 'Absent'
        CSharpPayloadLength = $payload.Length
        CSharpContainsNtSetTimerResolution = $payload.Contains('NtSetTimerResolution')
        CSharpContainsNtQueryTimerResolution = $payload.Contains('NtQueryTimerResolution')
        SourceWorkflow = @(
            'Apply writes the embedded C# payload to the source-defined Windows path.'
            'Apply compiles the payload with the source-defined .NET Framework compiler path and arguments.'
            'Apply removes the temporary .cs file.'
            'Apply deletes an existing Set Timer Resolution Service when present, then creates, autostarts, and runs the service.'
            'Apply sets GlobalTimerResolutionRequests to DWORD 1.'
            'Default disables, stops, deletes the service, deletes the generated executable, and deletes GlobalTimerResolutionRequests.'
            'Both source branches launch taskmgr.exe for verification.'
        )
        ExternalArtifacts = @()
        Downloads = @()
        SupportsOpen = $false
        SupportsRestore = $false
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
            Apply = 'Timer Resolution: On (Recommended)'
            Default = 'Timer Resolution: Default'
        }
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string]$OperatingSystem = $env:OS,

        [string]$SystemDrive = $env:SystemDrive,

        [string]$SystemRoot = $env:SystemRoot,

        [scriptblock]$PathChecker = {
            param($Path)
            Test-Path -LiteralPath $Path -PathType Leaf
        },

        [scriptblock]$CommandResolver = {
            param($CommandName)
            Get-Command -Name $CommandName -ErrorAction SilentlyContinue
        },

        [string]$SourcePath = $script:BoostLabTimerSourcePath
    )

    $sourceInfo = Get-BoostLabTimerSourceInfo -SourcePath $SourcePath
    $paths = Get-BoostLabTimerPaths -SystemDrive $SystemDrive
    $compilerAvailable = [bool](& $PathChecker $paths.CompilerPath)
    $cmdPath = if ([string]::IsNullOrWhiteSpace($SystemRoot)) { '' } else { Join-Path $SystemRoot 'System32\cmd.exe' }
    $cmdAvailable = (-not [string]::IsNullOrWhiteSpace($cmdPath) -and [bool](& $PathChecker $cmdPath))
    $missingCommands = @(
        foreach ($commandName in @('Get-Service', 'New-Service', 'Set-Service', 'Start-Process', 'Remove-Item', 'Set-Content')) {
            $resolved = @(& $CommandResolver $commandName)
            if ($resolved.Count -eq 0) {
                $commandName
            }
        }
    )
    $supported = (
        $OperatingSystem -eq 'Windows_NT' -and
        -not [string]::IsNullOrWhiteSpace($SystemDrive) -and
        $sourceInfo.HashMatches -and
        $compilerAvailable -and
        $cmdAvailable -and
        $missingCommands.Count -eq 0
    )

    [pscustomobject]@{
        Supported = $supported
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        SourceHashMatches = $sourceInfo.HashMatches
        CompilerAvailable = $compilerAvailable
        CommandProcessorAvailable = $cmdAvailable
        MissingCommands = $missingCommands
        Reason = if ($OperatingSystem -ne 'Windows_NT') {
            'Timer Resolution Assistant requires Windows.'
        }
        elseif ([string]::IsNullOrWhiteSpace($SystemDrive)) {
            'Timer Resolution Assistant requires SystemDrive.'
        }
        elseif (-not $sourceInfo.HashMatches) {
            'Timer Resolution Assistant Ultimate source identity could not be verified.'
        }
        elseif (-not $compilerAvailable) {
            "Timer Resolution Assistant requires the source-defined compiler: $($paths.CompilerPath)."
        }
        elseif (-not $cmdAvailable) {
            'Timer Resolution Assistant requires the Windows command processor.'
        }
        elseif ($missingCommands.Count -gt 0) {
            'Timer Resolution Assistant is unavailable because required commands were not found: {0}.' -f ($missingCommands -join ', ')
        }
        else {
            'The required Timer Resolution source identity, compiler, and command surface are available.'
        }
        Timestamp = Get-Date
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceInfo = Get-BoostLabTimerSourceInfo
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

function Invoke-BoostLabTimerCommand {
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

function Invoke-BoostLabTimerServiceOperation {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Get', 'New', 'SetStartupAuto', 'SetRunning', 'SetStartupDisabled', 'SetStopped')]
        [string]$Operation,

        [Parameter(Mandatory)]
        [string]$ServiceName,

        [string]$BinaryPathName = ''
    )

    switch ($Operation) {
        'Get' {
            $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
            [pscustomobject]@{ Success = $true; Exists = ($null -ne $service); Output = '' }
        }
        'New' {
            New-Service -Name $ServiceName -BinaryPathName $BinaryPathName -ErrorAction SilentlyContinue | Out-Null
            [pscustomobject]@{ Success = $true; Exists = $true; Output = '' }
        }
        'SetStartupAuto' {
            Set-Service -Name $ServiceName -StartupType Auto -ErrorAction SilentlyContinue | Out-Null
            [pscustomobject]@{ Success = $true; Output = '' }
        }
        'SetRunning' {
            Set-Service -Name $ServiceName -Status Running -ErrorAction SilentlyContinue | Out-Null
            [pscustomobject]@{ Success = $true; Output = '' }
        }
        'SetStartupDisabled' {
            Set-Service -Name $ServiceName -StartupType Disabled -ErrorAction SilentlyContinue | Out-Null
            [pscustomobject]@{ Success = $true; Output = '' }
        }
        'SetStopped' {
            Set-Service -Name $ServiceName -Status Stopped -ErrorAction SilentlyContinue | Out-Null
            [pscustomobject]@{ Success = $true; Output = '' }
        }
    }
}

function Invoke-BoostLabTimerProcess {
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [string]$ArgumentList = '',

        [bool]$Wait = $false,

        [string]$WindowStyle = ''
    )

    $parameters = @{
        FilePath = $FilePath
        ErrorAction = 'Stop'
    }
    if (-not [string]::IsNullOrWhiteSpace($ArgumentList)) {
        $parameters['ArgumentList'] = $ArgumentList
    }
    if ($Wait) {
        $parameters['Wait'] = $true
    }
    if (-not [string]::IsNullOrWhiteSpace($WindowStyle)) {
        $parameters['WindowStyle'] = $WindowStyle
    }

    Start-Process @parameters | Out-Null
    [pscustomobject]@{ Success = $true; Output = '' }
}

function Invoke-BoostLabTimerResolutionAction {
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

        [scriptblock]$FileRemover = {
            param($Path)
            Remove-Item $Path -Force -ErrorAction SilentlyContinue | Out-Null
            [pscustomobject]@{ Success = $true; Output = '' }
        },

        [scriptblock]$ProcessInvoker = {
            param($FilePath, $ArgumentList, $Wait, $WindowStyle)
            Invoke-BoostLabTimerProcess -FilePath $FilePath -ArgumentList $ArgumentList -Wait:$Wait -WindowStyle $WindowStyle
        },

        [scriptblock]$ServiceInvoker = {
            param($Operation, $ServiceName, $BinaryPathName)
            Invoke-BoostLabTimerServiceOperation -Operation $Operation -ServiceName $ServiceName -BinaryPathName $BinaryPathName
        },

        [scriptblock]$CommandInvoker = {
            param($CommandText)
            Invoke-BoostLabTimerCommand -CommandText $CommandText
        },

        [scriptblock]$SleepInvoker = {
            param($Seconds)
            Start-Sleep -Seconds $Seconds
            [pscustomobject]@{ Success = $true; Output = '' }
        },

        [string]$SystemDrive = $env:SystemDrive,

        [string]$SourcePath = $script:BoostLabTimerSourcePath
    )

    if (-not [bool](& $AdministratorChecker)) {
        return New-BoostLabTimerResolutionResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Administrator rights are required to change Timer Resolution Assistant service and registry state.'
    }

    try {
        $sourceInfo = Assert-BoostLabTimerSourceIdentity -SourcePath $SourcePath
        $paths = Get-BoostLabTimerPaths -SystemDrive $SystemDrive
        $payload = Get-BoostLabTimerCSharpPayload -SourcePath $SourcePath
    }
    catch {
        return New-BoostLabTimerResolutionResult `
            -Success $false `
            -Action $ActionName `
            -Message $_.Exception.Message
    }

    $operations = [System.Collections.Generic.List[object]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()
    $registryAddCommand = 'reg add "{0}" /v "{1}" /t REG_DWORD /d "1" /f >nul 2>&1' -f $script:BoostLabTimerRegistryCommandPath, $script:BoostLabTimerRegistryValueName
    $registryDeleteCommand = 'reg delete "{0}" /v "{1}" /f >nul 2>&1' -f $script:BoostLabTimerRegistryCommandPath, $script:BoostLabTimerRegistryValueName

    $steps = if ($ActionName -eq 'Apply') {
        @(
            [pscustomobject]@{ Name = 'WriteCSharpSource'; Invoke = { & $FileWriter $paths.GeneratedSourcePath $payload } }
            [pscustomobject]@{ Name = 'CompileServiceExecutable'; Invoke = { & $ProcessInvoker $paths.CompilerPath $paths.CompilerArguments $true 'Hidden' } }
            [pscustomobject]@{ Name = 'RemoveCSharpSource'; Invoke = { & $FileRemover $paths.GeneratedSourcePath } }
            [pscustomobject]@{ Name = 'GetExistingService'; Invoke = { & $ServiceInvoker 'Get' $script:BoostLabTimerServiceName '' } }
            [pscustomobject]@{ Name = 'DeleteExistingServiceIfPresent'; Invoke = {
                $lastGet = @($operations | Where-Object { [string]$_.Step -eq 'GetExistingService' } | Select-Object -Last 1)
                $exists = if ($lastGet.Count -gt 0) {
                    [bool](Get-BoostLabTimerPropertyValue -InputObject $lastGet[0].Result -Name 'Exists' -DefaultValue $false)
                }
                else { $false }
                if ($exists) {
                    $deleteResult = & $CommandInvoker ('sc.exe delete "{0}"' -f $script:BoostLabTimerServiceName)
                    if ([bool](Get-BoostLabTimerPropertyValue -InputObject $deleteResult -Name 'Success' -DefaultValue $true)) {
                        & $SleepInvoker 2 | Out-Null
                    }
                    $deleteResult
                }
                else {
                    [pscustomobject]@{ Success = $true; Skipped = $true; Output = 'Existing service was not detected.' }
                }
            } }
            [pscustomobject]@{ Name = 'NewService'; Invoke = { & $ServiceInvoker 'New' $script:BoostLabTimerServiceName $paths.GeneratedExecutablePath } }
            [pscustomobject]@{ Name = 'SetServiceStartupAuto'; Invoke = { & $ServiceInvoker 'SetStartupAuto' $script:BoostLabTimerServiceName '' } }
            [pscustomobject]@{ Name = 'SetServiceRunning'; Invoke = { & $ServiceInvoker 'SetRunning' $script:BoostLabTimerServiceName '' } }
            [pscustomobject]@{ Name = 'EnableGlobalTimerResolutionRequests'; Invoke = { & $CommandInvoker $registryAddCommand } }
            [pscustomobject]@{ Name = 'OpenTaskManager'; Invoke = { & $ProcessInvoker 'taskmgr.exe' '' $false '' } }
        )
    }
    else {
        @(
            [pscustomobject]@{ Name = 'SetServiceStartupDisabled'; Invoke = { & $ServiceInvoker 'SetStartupDisabled' $script:BoostLabTimerServiceName '' } }
            [pscustomobject]@{ Name = 'SetServiceStopped'; Invoke = { & $ServiceInvoker 'SetStopped' $script:BoostLabTimerServiceName '' } }
            [pscustomobject]@{ Name = 'DeleteService'; Invoke = { & $CommandInvoker ('sc.exe delete "{0}"' -f $script:BoostLabTimerServiceName) } }
            [pscustomobject]@{ Name = 'RemoveServiceExecutable'; Invoke = { & $FileRemover $paths.GeneratedExecutablePath } }
            [pscustomobject]@{ Name = 'DisableGlobalTimerResolutionRequests'; Invoke = { & $CommandInvoker $registryDeleteCommand } }
            [pscustomobject]@{ Name = 'OpenTaskManager'; Invoke = { & $ProcessInvoker 'taskmgr.exe' '' $false '' } }
        )
    }

    foreach ($step in $steps) {
        try {
            $result = & $step.Invoke
            $operations.Add([pscustomobject]@{ Step = $step.Name; Result = $result })
            if (-not [bool](Get-BoostLabTimerPropertyValue -InputObject $result -Name 'Success' -DefaultValue $true)) {
                $errors.Add(("{0} failed: {1}" -f $step.Name, (Get-BoostLabTimerPropertyValue -InputObject $result -Name 'Output' -DefaultValue 'Unknown failure')))
                break
            }
        }
        catch {
            $errors.Add("$($step.Name) failed: $($_.Exception.Message)")
            break
        }
    }

    $branchLabel = if ($ActionName -eq 'Apply') {
        'Timer Resolution: On (Recommended)'
    }
    else {
        'Timer Resolution: Default'
    }
    $data = [pscustomobject]@{
        SourcePath = $sourceInfo.SourcePath
        SourceSha256 = $sourceInfo.ActualSha256
        SourceBranchLabel = $branchLabel
        ServiceName = $script:BoostLabTimerServiceName
        InternalServiceName = $script:BoostLabTimerInternalServiceName
        GeneratedSourcePath = $paths.GeneratedSourcePath
        GeneratedExecutablePath = $paths.GeneratedExecutablePath
        CompilerPath = $paths.CompilerPath
        CompilerArguments = $paths.CompilerArguments
        RegistryPath = $script:BoostLabTimerRegistryDisplayPath
        RegistryValueName = $script:BoostLabTimerRegistryValueName
        RegistryCommand = if ($ActionName -eq 'Apply') { $registryAddCommand } else { $registryDeleteCommand }
        Operations = $operations.ToArray()
        Errors = $errors.ToArray()
        Downloads = @()
        ExternalArtifacts = @()
        CompletedAt = Get-Date
    }

    $success = $errors.Count -eq 0
    $message = if (-not $success) {
        "Timer Resolution Assistant $branchLabel workflow failed: $($errors -join '; ')"
    }
    elseif ($ActionName -eq 'Apply') {
        'Timer Resolution Assistant On (Recommended) source workflow completed.'
    }
    else {
        'Timer Resolution Assistant Default source workflow completed.'
    }

    return New-BoostLabTimerResolutionResult `
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
        return New-BoostLabTimerResolutionResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Unsupported action. Only Analyze, Apply, and Default are allowed.'
    }

    if ($ActionName -eq 'Analyze') {
        return New-BoostLabTimerResolutionResult `
            -Success $true `
            -Action 'Analyze' `
            -Message 'Timer Resolution Assistant source workflow analyzed.' `
            -Data (Get-BoostLabTimerResolutionAnalyzeData)
    }

    if (-not $Confirmed) {
        return New-BoostLabTimerResolutionResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Cancelled by user' `
            -Cancelled $true
    }

    return Invoke-BoostLabTimerResolutionAction -ActionName $ActionName
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
