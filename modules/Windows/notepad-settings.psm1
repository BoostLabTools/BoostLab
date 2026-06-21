Set-StrictMode -Version Latest

$verificationModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1'
Import-Module -Name $verificationModulePath -Scope Local -ErrorAction Stop

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'notepad-settings'; Title = 'Notepad Settings'; Stage = 'Windows'; Order = 14
    Type = 'action'; RiskLevel = 'medium'
    Description = 'Apply the source-defined Notepad LocalState settings or reset Notepad by deleting its settings.dat.'
    Actions = @('Apply', 'Default')
    Capabilities = [ordered]@{
        RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false
        CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false
        CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false
        CanDeleteFiles = $true; UsesTrustedInstaller = $false; UsesSafeMode = $false
        SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Apply', 'Default')
$script:BoostLabNotepadProcessName = 'Notepad'
$script:BoostLabNotepadRelativeSettingsPath = 'Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe\Settings\settings.dat'
$script:BoostLabNotepadRegistryFileName = 'notepadsettings.reg'
$script:BoostLabNotepadRegistryFileContent = @'
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\Settings\LocalState]
"OpenFile"=hex(5f5e104):01,00,00,00,d1,55,24,57,d1,84,db,01
"GhostFile"=hex(5f5e10b):00,42,60,f1,5a,d1,84,db,01
"RewriteEnabled"=hex(5f5e10b):00,12,4a,7f,5f,d1,84,db,01
'@
$script:BoostLabNotepadExpectedValues = @(
    [pscustomobject]@{ Name = 'OpenFile'; Expected = '01,00,00,00,d1,55,24,57,d1,84,db,01' }
    [pscustomobject]@{ Name = 'GhostFile'; Expected = '00,42,60,f1,5a,d1,84,db,01' }
    [pscustomobject]@{ Name = 'RewriteEnabled'; Expected = '00,12,4a,7f,5f,d1,84,db,01' }
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

function Get-BoostLabNotepadPaths {
    param(
        [string]$LocalAppData = $env:LocalAppData,
        [string]$SystemRoot = $env:SystemRoot
    )

    [pscustomobject]@{
        SettingsDatPath = Join-Path $LocalAppData $script:BoostLabNotepadRelativeSettingsPath
        PackageDirectoryPath = Join-Path $LocalAppData 'Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe'
        RegistryFilePath = Join-Path $SystemRoot "Temp\$($script:BoostLabNotepadRegistryFileName)"
    }
}

function Get-BoostLabNotepadFileState {
    param([Parameter(Mandatory)][string]$Path)

    if (-not [IO.File]::Exists($Path)) {
        return [pscustomobject]@{
            ReadSucceeded = $true; Exists = $false; Path = $Path
            Sha256 = $null; Length = $null; Message = 'File is absent.'
        }
    }

    try {
        $file = [IO.FileInfo]::new($Path)
        return [pscustomobject]@{
            ReadSucceeded = $true; Exists = $true; Path = $Path
            Sha256 = (Get-FileHash -LiteralPath $Path -Algorithm SHA256 -ErrorAction Stop).Hash
            Length = $file.Length; Message = 'File state detected.'
        }
    }
    catch {
        return [pscustomobject]@{
            ReadSucceeded = $false; Exists = $true; Path = $Path
            Sha256 = $null; Length = $null; Message = $_.Exception.Message
        }
    }
}

function Stop-BoostLabNotepadProcess {
    try {
        Stop-Process -Name $script:BoostLabNotepadProcessName -Force -ErrorAction SilentlyContinue
        return [pscustomobject]@{ Success = $true; Status = 'StopRequested'; Message = 'Stop-Process Notepad was invoked with SilentlyContinue, matching Ultimate.' }
    }
    catch {
        return [pscustomobject]@{ Success = $false; Status = 'Failed'; Message = $_.Exception.Message }
    }
}

function Invoke-BoostLabNotepadRegistryCommand {
    param(
        [Parameter(Mandatory)][ValidateSet('load', 'import', 'unload')][string]$Operation,
        [Parameter(Mandatory)][string[]]$Arguments,
        [string]$SystemRoot = $env:SystemRoot
    )

    $regPath = Join-Path $SystemRoot 'System32\reg.exe'
    $output = @(& $regPath $Operation @Arguments 2>&1)
    $exitCode = if ($null -eq $LASTEXITCODE) { 0 } else { [int]$LASTEXITCODE }
    return [pscustomobject]@{
        Success = $exitCode -eq 0
        Operation = $Operation
        ExitCode = $exitCode
        Output = $output
    }
}

function ConvertTo-BoostLabNotepadValueDisplay {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) {
        return 'Absent'
    }
    if ($Value -is [byte[]]) {
        return (@($Value | ForEach-Object { $_.ToString('x2') }) -join ',')
    }
    return [string]$Value
}

function Get-BoostLabNotepadRegistryValue {
    param([Parameter(Mandatory)][string]$Name)

    try {
        $item = Get-ItemProperty -LiteralPath 'HKLM:\Settings\LocalState' -ErrorAction Stop
        $property = $item.PSObject.Properties[$Name]
        if ($null -eq $property) {
            return [pscustomobject]@{
                ReadSucceeded = $true; Exists = $false; Name = $Name
                DisplayValue = 'Absent'; Message = 'Registry value is absent.'
            }
        }
        return [pscustomobject]@{
            ReadSucceeded = $true; Exists = $true; Name = $Name
            DisplayValue = ConvertTo-BoostLabNotepadValueDisplay -Value $property.Value
            Message = 'Registry value detected.'
        }
    }
    catch {
        return [pscustomobject]@{
            ReadSucceeded = $false; Exists = $false; Name = $Name
            DisplayValue = 'Unknown'; Message = $_.Exception.Message
        }
    }
}

function Invoke-BoostLabNotepadFileRemoval {
    param([Parameter(Mandatory)][string]$Path)

    try {
        Remove-Item -LiteralPath $Path -Force -ErrorAction Stop
        return [pscustomobject]@{ Success = $true; Message = 'settings.dat delete was invoked.' }
    }
    catch {
        return [pscustomobject]@{ Success = $false; Message = $_.Exception.Message }
    }
}

function New-BoostLabNotepadResult {
    param(
        [Parameter(Mandatory)][bool]$Success,
        [Parameter(Mandatory)][string]$Action,
        [Parameter(Mandatory)][string]$Message,
        [string]$Status = '',
        [AllowNull()][object]$Data = $null,
        [AllowNull()][object]$VerificationResult = $null,
        [bool]$Cancelled = $false
    )

    $resolvedStatus = if (-not [string]::IsNullOrWhiteSpace($Status)) {
        $Status
    }
    elseif ($Success) {
        'Passed'
    }
    else {
        'Failed'
    }

    [pscustomobject]@{
        Success = $Success
        ToolId = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Action = $Action
        Status = $resolvedStatus
        Message = $Message
        RestartRequired = $false
        Cancelled = $Cancelled
        Timestamp = Get-Date
        Data = $Data
        VerificationResult = $VerificationResult
    }
}

function New-BoostLabNotepadFailureVerification {
    param(
        [Parameter(Mandatory)][string]$Action,
        [Parameter(Mandatory)][string]$Message
    )

    New-BoostLabVerificationResult `
        -ToolId 'notepad-settings' `
        -ToolTitle 'Notepad Settings' `
        -Action $Action `
        -Status 'Failed' `
        -ExpectedState ([pscustomobject]@{ NotepadSettings = if ($Action -eq 'Apply') { 'Ultimate Apply command sequence completes' } else { 'Ultimate Default delete command completes' } }) `
        -DetectedState ([pscustomobject]@{ NotepadSettings = 'Operation failed' }) `
        -Checks @(
            New-BoostLabVerificationCheck `
                -Name 'Notepad Settings operation' `
                -Expected 'Completed without terminating error' `
                -Actual $Message `
                -Status 'Failed' `
                -Message $Message
        ) `
        -Message $Message
}

function New-BoostLabNotepadApplyVerification {
    param(
        [Parameter(Mandatory)][object]$LoadResult,
        [object[]]$RegistryStates = @(),
        [Parameter(Mandatory)][object]$FileState
    )

    $checks = [System.Collections.Generic.List[object]]::new()
    $loadSucceeded = $null -ne $LoadResult -and [bool]$LoadResult.Success
    $checks.Add((New-BoostLabVerificationCheck `
        -Name 'reg load HKLM\Settings' `
        -Expected 'Exit code 0 imports source-defined values; non-zero skips import per Ultimate source.' `
        -Actual $(if ($null -eq $LoadResult) { 'No load result' } else { "ExitCode=$($LoadResult.ExitCode)" }) `
        -Status $(if ($loadSucceeded) { 'Passed' } else { 'Warning' }) `
        -Message $(if ($loadSucceeded) { 'Notepad settings.dat was mounted.' } else { 'reg load did not succeed; Ultimate skips import and exits after the load attempt.' })))

    foreach ($definition in $script:BoostLabNotepadExpectedValues) {
        $state = @($RegistryStates | Where-Object { $_.Name -eq $definition.Name }) | Select-Object -First 1
        $status = if (-not $loadSucceeded) {
            'Warning'
        }
        elseif ($null -eq $state -or -not [bool]$state.ReadSucceeded) {
            'Warning'
        }
        elseif (-not [bool]$state.Exists -or [string]$state.DisplayValue -ne [string]$definition.Expected) {
            'Failed'
        }
        else {
            'Passed'
        }
        $actual = if ($null -eq $state) { if ($loadSucceeded) { 'Unknown' } else { 'Not checked because hive load failed.' } } else { [string]$state.DisplayValue }
        $message = if ($null -eq $state) { if ($loadSucceeded) { 'Registry value was not captured.' } else { 'Source import was skipped because reg load failed.' } } else { [string]$state.Message }
        $checks.Add((New-BoostLabVerificationCheck `
            -Name "Notepad LocalState | $($definition.Name)" `
            -Expected ([string]$definition.Expected) `
            -Actual $actual `
            -Status $status `
            -Message $message))
    }

    $checks.Add((New-BoostLabVerificationCheck `
        -Name 'settings.dat after Apply' `
        -Expected 'Source-targeted path checked after Ultimate sequence' `
        -Actual $(if (-not [bool]$FileState.ReadSucceeded) { 'Unknown' } elseif ([bool]$FileState.Exists) { 'Present' } else { 'Absent' }) `
        -Status $(if (-not [bool]$FileState.ReadSucceeded) { 'Warning' } else { 'Passed' }) `
        -Message ([string]$FileState.Message)))

    $statuses = @($checks | ForEach-Object { $_.Status })
    $overall = if ('Failed' -in $statuses) { 'Failed' } elseif ('Warning' -in $statuses) { 'Warning' } else { 'Passed' }
    New-BoostLabVerificationResult `
        -ToolId 'notepad-settings' `
        -ToolTitle 'Notepad Settings' `
        -Action 'Apply' `
        -Status $overall `
        -ExpectedState ([pscustomobject]@{ NotepadSettings = 'Ultimate Apply sequence executed' }) `
        -DetectedState ([pscustomobject]@{ NotepadSettings = "$(@($checks | Where-Object Status -eq 'Passed').Count) passed, $(@($checks | Where-Object Status -eq 'Warning').Count) warning, $(@($checks | Where-Object Status -eq 'Failed').Count) failed" }) `
        -Checks $checks.ToArray() `
        -Message $(if ($overall -eq 'Passed') { 'Notepad settings verified.' } elseif ($overall -eq 'Warning') { 'Notepad Apply matched the source control flow, but import verification was unavailable or skipped.' } else { 'Notepad settings verification failed.' })
}

function New-BoostLabNotepadDefaultVerification {
    param(
        [Parameter(Mandatory)][object]$FileState,
        [Parameter(Mandatory)][object]$RemoveResult
    )

    $checks = [System.Collections.Generic.List[object]]::new()
    $checks.Add((New-BoostLabVerificationCheck `
        -Name 'Remove-Item settings.dat' `
        -Expected 'Delete command attempted against exact source path' `
        -Actual $(if ($null -eq $RemoveResult) { 'No delete result' } else { [string]$RemoveResult.Message }) `
        -Status $(if ($null -ne $RemoveResult -and [bool]$RemoveResult.Success) { 'Passed' } else { 'Warning' }) `
        -Message $(if ($null -ne $RemoveResult -and [bool]$RemoveResult.Success) { 'Delete command completed.' } else { 'Delete command was attempted; missing files or non-terminating errors still leave the source default state as absent.' })))
    $checks.Add((New-BoostLabVerificationCheck `
        -Name 'settings.dat after Default' `
        -Expected 'Absent' `
        -Actual $(if (-not [bool]$FileState.ReadSucceeded) { 'Unknown' } elseif ([bool]$FileState.Exists) { 'Present' } else { 'Absent' }) `
        -Status $(if (-not [bool]$FileState.ReadSucceeded) { 'Warning' } elseif ([bool]$FileState.Exists) { 'Failed' } else { 'Passed' }) `
        -Message ([string]$FileState.Message)))

    $statuses = @($checks | ForEach-Object { $_.Status })
    $overall = if ('Failed' -in $statuses) { 'Failed' } elseif ('Warning' -in $statuses) { 'Warning' } else { 'Passed' }
    New-BoostLabVerificationResult `
        -ToolId 'notepad-settings' `
        -ToolTitle 'Notepad Settings' `
        -Action 'Default' `
        -Status $overall `
        -ExpectedState ([pscustomobject]@{ NotepadSettings = 'settings.dat absent after source delete action' }) `
        -DetectedState ([pscustomobject]@{ NotepadSettings = if (-not [bool]$FileState.ReadSucceeded) { 'Unknown' } elseif ([bool]$FileState.Exists) { 'Present' } else { 'Absent' } }) `
        -Checks $checks.ToArray() `
        -Message $(if ($overall -eq 'Passed') { 'Notepad default state verified.' } elseif ($overall -eq 'Warning') { 'Notepad Default matched the source delete attempt, but delete status included a warning.' } else { 'Notepad Default verification failed.' })
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
    param(
        [string]$OperatingSystem = $env:OS,
        [string]$LocalAppData = $env:LocalAppData,
        [string]$SystemRoot = $env:SystemRoot,
        [scriptblock]$PathTester = {
            param($Path, $PathType)
            Test-Path -LiteralPath $Path -PathType $PathType
        }
    )

    $paths = Get-BoostLabNotepadPaths -LocalAppData $LocalAppData -SystemRoot $SystemRoot
    $regPath = if ([string]::IsNullOrWhiteSpace($SystemRoot)) { '' } else { Join-Path $SystemRoot 'System32\reg.exe' }
    $runtimeSupported = (
        $OperatingSystem -eq 'Windows_NT' -and
        -not [string]::IsNullOrWhiteSpace($LocalAppData) -and
        -not [string]::IsNullOrWhiteSpace($SystemRoot) -and
        (& $PathTester $regPath 'Leaf')
    )
    $packageDirectoryExists = if ([string]::IsNullOrWhiteSpace($LocalAppData)) {
        $false
    }
    else {
        [bool](& $PathTester $paths.PackageDirectoryPath 'Container')
    }
    $settingsDatExists = if ([string]::IsNullOrWhiteSpace($LocalAppData)) {
        $false
    }
    else {
        [bool](& $PathTester $paths.SettingsDatPath 'Leaf')
    }

    [pscustomobject]@{
        Supported = $runtimeSupported
        Applicable = $runtimeSupported
        ToolId = 'notepad-settings'
        ToolTitle = 'Notepad Settings'
        ExpectedSettingsDatPath = $paths.SettingsDatPath
        PackageDirectoryPath = $paths.PackageDirectoryPath
        PackageDirectoryExists = $packageDirectoryExists
        SettingsDatExists = $settingsDatExists
        Reason = if (-not $runtimeSupported) {
            'Notepad Settings requires Windows, LocalAppData, SystemRoot, and reg.exe.'
        }
        elseif (-not $settingsDatExists) {
            'settings.dat is absent; Ultimate still attempts the source Apply/Default command sequence rather than using an applicability short-circuit.'
        }
        else {
            'The source-targeted Notepad settings.dat is available.'
        }
        Timestamp = Get-Date
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $paths = Get-BoostLabNotepadPaths
    $state = Get-BoostLabNotepadFileState -Path $paths.SettingsDatPath
    [pscustomobject]@{
        ToolId = 'notepad-settings'
        ToolTitle = 'Notepad Settings'
        Status = if (-not [bool]$state.ReadSucceeded) { 'Unavailable' } elseif ([bool]$state.Exists) { 'settings.dat present' } else { 'settings.dat absent' }
        LastAction = $null
        LastResult = $null
        RestartRequired = $false
        Timestamp = Get-Date
    }
}

function Invoke-BoostLabNotepadSettingsAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][ValidateSet('Apply', 'Default')][string]$ActionName,
        [bool]$Confirmed = $false,
        [scriptblock]$AdministratorChecker = { Test-BoostLabAdministrator },
        [scriptblock]$ProcessStopper = { Stop-BoostLabNotepadProcess },
        [scriptblock]$DelayInvoker = { param($Seconds) Start-Sleep -Seconds $Seconds },
        [scriptblock]$FileStateReader = { param($Path) Get-BoostLabNotepadFileState -Path $Path },
        [scriptblock]$RegistryFileWriter = { param($Path, $Content) Set-Content -LiteralPath $Path -Value $Content -Force -ErrorAction Stop },
        [scriptblock]$RegistryCommandInvoker = { param($Operation, $Arguments, $Root) Invoke-BoostLabNotepadRegistryCommand -Operation $Operation -Arguments $Arguments -SystemRoot $Root },
        [scriptblock]$RegistryReader = { param($Name) Get-BoostLabNotepadRegistryValue -Name $Name },
        [scriptblock]$FileRemover = { param($Path) Invoke-BoostLabNotepadFileRemoval -Path $Path },
        [string]$LocalAppData = $env:LocalAppData,
        [string]$SystemRoot = $env:SystemRoot
    )

    if (-not $Confirmed) {
        return New-BoostLabNotepadResult -Success $false -Action $ActionName -Message 'Explicit confirmation is required.' -Cancelled $true
    }
    if (-not (& $AdministratorChecker)) {
        return New-BoostLabNotepadResult -Success $false -Action $ActionName -Message 'Administrator rights are required.'
    }

    $paths = Get-BoostLabNotepadPaths -LocalAppData $LocalAppData -SystemRoot $SystemRoot
    $processResult = $null
    try {
        $processResult = & $ProcessStopper
        if ($null -eq $processResult -or -not [bool]$processResult.Success) {
            $message = if ($null -eq $processResult) { 'Notepad process handling returned no result.' } else { [string]$processResult.Message }
            $verification = New-BoostLabNotepadFailureVerification -Action $ActionName -Message $message
            return New-BoostLabNotepadResult -Success $false -Action $ActionName -Message $message -VerificationResult $verification
        }
        & $DelayInvoker 2

        if ($ActionName -eq 'Apply') {
            & $RegistryFileWriter $paths.RegistryFilePath $script:BoostLabNotepadRegistryFileContent
            $registryStates = @()
            $hiveOperations = [System.Collections.Generic.List[string]]::new()
            $loadResult = & $RegistryCommandInvoker 'load' @('HKLM\Settings', $paths.SettingsDatPath) $SystemRoot
            $hiveOperations.Add("reg load HKLM\Settings exited with code $($loadResult.ExitCode).")
            if ($null -ne $loadResult -and [bool]$loadResult.Success) {
                & $RegistryCommandInvoker 'import' @($paths.RegistryFilePath) $SystemRoot | Out-Null
                $hiveOperations.Add('reg import notepadsettings.reg was invoked.')
                $registryStates = @(
                    foreach ($definition in $script:BoostLabNotepadExpectedValues) {
                        $state = & $RegistryReader $definition.Name
                        if ($null -eq $state) {
                            [pscustomobject]@{
                                ReadSucceeded = $false; Exists = $false; Name = $definition.Name
                                DisplayValue = 'Unknown'; Message = 'Registry reader returned no result.'
                            }
                        }
                        else {
                            $state
                        }
                    }
                )
                [gc]::Collect()
                & $DelayInvoker 2
                & $RegistryCommandInvoker 'unload' @('HKLM\Settings') $SystemRoot | Out-Null
                $hiveOperations.Add('reg unload HKLM\Settings was invoked.')
            }

            $detectedFileState = & $FileStateReader $paths.SettingsDatPath
            $verificationResult = New-BoostLabNotepadApplyVerification `
                -LoadResult $loadResult `
                -RegistryStates @($registryStates) `
                -FileState $detectedFileState
            $success = $verificationResult.Status -ne 'Failed'
            $message = if ($success) { 'Notepad settings Apply source sequence completed.' } else { 'Notepad settings Apply source sequence completed, but verification failed.' }
            $data = [pscustomobject]@{
                CommandStatus = if ($success) { 'Completed' } else { 'Completed with verification failure' }
                VerificationStatus = $verificationResult.Status
                ExpectedNotepadSettingsState = 'Ultimate Apply writes source-defined OpenFile, GhostFile, and RewriteEnabled values when reg load succeeds'
                DetectedNotepadSettingsState = $verificationResult.DetectedState.NotepadSettings
                SettingsDatPath = $paths.SettingsDatPath
                NotepadPackageDirectoryPath = $paths.PackageDirectoryPath
                SettingsDatExists = [bool]$detectedFileState.Exists
                ChangesExecuted = $true
                BackupStatus = 'Not used; Ultimate source does not create a backup.'
                BackupPath = ''
                OriginalSha256 = $null
                DetectedSha256 = $detectedFileState.Sha256
                ProcessActions = @([string]$processResult.Message)
                HiveOperations = $hiveOperations.ToArray()
                RegistryValuesChecked = @($registryStates | ForEach-Object { "$($_.Name): $($_.DisplayValue)" })
                FileDisposition = 'settings.dat was targeted through the source-defined mounted hive sequence.'
                Warnings = @()
                CompletedAt = Get-Date
            }
            return New-BoostLabNotepadResult -Success $success -Action $ActionName -Message $message -Data $data -VerificationResult $verificationResult
        }

        $removeResult = & $FileRemover $paths.SettingsDatPath
        $detectedFileState = & $FileStateReader $paths.SettingsDatPath
        $verificationResult = New-BoostLabNotepadDefaultVerification `
            -FileState $detectedFileState `
            -RemoveResult $removeResult
        $success = $verificationResult.Status -ne 'Failed'
        $message = if ($success) { 'Notepad settings Default source sequence completed.' } else { 'Notepad Default source sequence completed, but verification failed.' }
        $data = [pscustomobject]@{
            CommandStatus = if ($success) { 'Completed' } else { 'Completed with verification failure' }
            VerificationStatus = $verificationResult.Status
            ExpectedNotepadSettingsState = 'settings.dat absent after source-defined Remove-Item'
            DetectedNotepadSettingsState = $verificationResult.DetectedState.NotepadSettings
            SettingsDatPath = $paths.SettingsDatPath
            NotepadPackageDirectoryPath = $paths.PackageDirectoryPath
            SettingsDatExists = [bool]$detectedFileState.Exists
            ChangesExecuted = $true
            BackupStatus = 'Not used; Ultimate source does not create a backup.'
            BackupPath = ''
            OriginalSha256 = $null
            DetectedSha256 = $detectedFileState.Sha256
            ProcessActions = @([string]$processResult.Message)
            HiveOperations = @()
            RegistryValuesChecked = @()
            FileDisposition = 'Delete was attempted only against the exact source-defined settings.dat path.'
            Warnings = @()
            CompletedAt = Get-Date
        }
        return New-BoostLabNotepadResult -Success $success -Action $ActionName -Message $message -Data $data -VerificationResult $verificationResult
    }
    catch {
        $message = $_.Exception.Message
        $verificationResult = New-BoostLabNotepadFailureVerification -Action $ActionName -Message $message
        $data = [pscustomobject]@{
            CommandStatus = 'Failed'
            VerificationStatus = 'Failed'
            ExpectedNotepadSettingsState = if ($ActionName -eq 'Apply') { 'Ultimate Apply source sequence completed' } else { 'settings.dat absent' }
            DetectedNotepadSettingsState = 'Operation failed'
            SettingsDatPath = $paths.SettingsDatPath
            NotepadPackageDirectoryPath = $paths.PackageDirectoryPath
            SettingsDatExists = $null
            ChangesExecuted = $true
            BackupStatus = 'Not used; Ultimate source does not create a backup.'
            BackupPath = ''
            OriginalSha256 = $null
            DetectedSha256 = $null
            ProcessActions = @($(if ($null -eq $processResult) { 'Unknown' } else { [string]$processResult.Message }))
            HiveOperations = @()
            RegistryValuesChecked = @()
            FileDisposition = 'Operation stopped after a terminating error.'
            Warnings = @()
            CompletedAt = Get-Date
        }
        return New-BoostLabNotepadResult -Success $false -Action $ActionName -Message $message -Data $data -VerificationResult $verificationResult
    }
}

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][ValidateSet('Apply', 'Default')][string]$ActionName,
        [bool]$Confirmed = $false
    )

    Invoke-BoostLabNotepadSettingsAction -ActionName $ActionName -Confirmed:$Confirmed
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([bool]$Confirmed = $false)

    Invoke-BoostLabNotepadSettingsAction -ActionName 'Default' -Confirmed:$Confirmed
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
)
