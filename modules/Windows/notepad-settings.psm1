Set-StrictMode -Version Latest

$verificationModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1'
Import-Module -Name $verificationModulePath -Scope Local -ErrorAction Stop

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'notepad-settings'; Title = 'Notepad Settings'; Stage = 'Windows'; Order = 14
    Type = 'action'; RiskLevel = 'medium'
    Description = 'Apply the approved Notepad settings or reset Notepad by deleting its settings.dat after a verified backup.'
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
        [string]$SystemRoot = $env:SystemRoot,
        [string]$ProgramData = $env:ProgramData,
        [string]$BackupId = ('{0}-{1}' -f (Get-Date -Format 'yyyyMMdd-HHmmssfff'), [guid]::NewGuid().ToString('N'))
    )

    $stateDirectory = Join-Path $ProgramData 'BoostLab\State'
    $backupDirectory = Join-Path $stateDirectory "Backups\NotepadSettings\$BackupId"
    [pscustomobject]@{
        SettingsDatPath = Join-Path $LocalAppData $script:BoostLabNotepadRelativeSettingsPath
        PackageDirectoryPath = Join-Path $LocalAppData 'Packages\Microsoft.WindowsNotepad_8wekyb3d8bbwe'
        RegistryFilePath = Join-Path $SystemRoot "Temp\$($script:BoostLabNotepadRegistryFileName)"
        StateDirectory = $stateDirectory
        ManifestPath = Join-Path $stateDirectory 'notepad-settings.json'
        BackupDirectory = $backupDirectory
        BackupPath = Join-Path $backupDirectory 'settings.dat'
    }
}

function Test-BoostLabNotepadSettingsPath {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$LocalAppData
    )

    try {
        $expected = [IO.Path]::GetFullPath((Join-Path $LocalAppData $script:BoostLabNotepadRelativeSettingsPath))
        return [IO.Path]::GetFullPath($Path).Equals($expected, [StringComparison]::OrdinalIgnoreCase)
    }
    catch {
        return $false
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

function Backup-BoostLabNotepadSettingsFile {
    param(
        [Parameter(Mandatory)][string]$SourcePath,
        [Parameter(Mandatory)][string]$BackupPath
    )

    try {
        $directory = Split-Path -Parent $BackupPath
        [IO.Directory]::CreateDirectory($directory) | Out-Null
        Copy-Item -LiteralPath $SourcePath -Destination $BackupPath -Force -ErrorAction Stop
        $sourceHash = (Get-FileHash -LiteralPath $SourcePath -Algorithm SHA256 -ErrorAction Stop).Hash
        $backupHash = (Get-FileHash -LiteralPath $BackupPath -Algorithm SHA256 -ErrorAction Stop).Hash
        if ($sourceHash -ne $backupHash) {
            throw 'The Notepad settings backup hash does not match the source file.'
        }
        return [pscustomobject]@{
            Success = $true; BackupPath = $BackupPath; Sha256 = $backupHash
            Message = 'Verified settings.dat backup created.'
        }
    }
    catch {
        return [pscustomobject]@{
            Success = $false; BackupPath = $BackupPath; Sha256 = $null
            Message = $_.Exception.Message
        }
    }
}

function Save-BoostLabNotepadState {
    param(
        [Parameter(Mandatory)][object]$State,
        [Parameter(Mandatory)][string]$ManifestPath
    )

    $directory = Split-Path -Parent $ManifestPath
    [IO.Directory]::CreateDirectory($directory) | Out-Null
    $State | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ManifestPath -Encoding UTF8 -Force -ErrorAction Stop
}

function Stop-BoostLabNotepadProcess {
    try {
        $processes = @(Get-Process -Name $script:BoostLabNotepadProcessName -ErrorAction SilentlyContinue)
        if ($processes.Count -eq 0) {
            return [pscustomobject]@{ Success = $true; Status = 'Not running'; Message = 'Notepad was not running.' }
        }
        Stop-Process -Name $script:BoostLabNotepadProcessName -Force -ErrorAction Stop
        return [pscustomobject]@{ Success = $true; Status = 'Stopped'; Message = 'Notepad stopped.' }
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
    if ($LASTEXITCODE -ne 0) {
        throw "reg $Operation failed with exit code $LASTEXITCODE. $($output -join ' ')"
    }
    return [pscustomobject]@{ Success = $true; Operation = $Operation; Output = $output }
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

function New-BoostLabNotepadNotApplicableResult {
    param(
        [Parameter(Mandatory)][string]$Action,
        [Parameter(Mandatory)][object]$Paths,
        [Parameter(Mandatory)][bool]$PackageDirectoryExists
    )

    $compatibilityMessage = 'The source-targeted Notepad settings.dat is absent. This system may be using classic Notepad or a Notepad build that does not expose the source-targeted settings.dat.'
    $data = [pscustomobject]@{
        CommandStatus = 'Not applicable'
        VerificationStatus = 'NotApplicable'
        CompatibilityStatus = 'Not applicable'
        CompatibilityMessage = $compatibilityMessage
        ExpectedNotepadSettingsState = 'The exact source-targeted settings.dat exists'
        DetectedNotepadSettingsState = 'settings.dat absent'
        SettingsDatPath = [string]$Paths.SettingsDatPath
        NotepadPackageDirectoryPath = [string]$Paths.PackageDirectoryPath
        NotepadPackageDirectoryExists = $PackageDirectoryExists
        SettingsDatExists = $false
        ChangesExecuted = $false
        BackupStatus = 'Not attempted'
        BackupPath = ''
        OriginalSha256 = $null
        DetectedSha256 = $null
        ProcessActions = @('None; applicability was checked before process handling.')
        HiveOperations = @()
        RegistryValuesChecked = @()
        FileDisposition = 'No changes executed.'
        Warnings = @($compatibilityMessage)
        CompletedAt = Get-Date
    }

    return New-BoostLabNotepadResult `
        -Success $true `
        -Action $Action `
        -Status 'NotApplicable' `
        -Message $compatibilityMessage `
        -Data $data
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
        -ExpectedState ([pscustomobject]@{ NotepadSettings = if ($Action -eq 'Apply') { 'Approved values present' } else { 'settings.dat absent' } }) `
        -DetectedState ([pscustomobject]@{ NotepadSettings = 'Operation failed' }) `
        -Checks @(
            New-BoostLabVerificationCheck `
                -Name 'Notepad Settings operation' `
                -Expected 'Completed without error' `
                -Actual $Message `
                -Status 'Failed' `
                -Message $Message
        ) `
        -Message $Message
}

function New-BoostLabNotepadApplyVerification {
    param(
        [Parameter(Mandatory)][object[]]$RegistryStates,
        [Parameter(Mandatory)][object]$FileState,
        [Parameter(Mandatory)][object]$BackupResult
    )

    $checks = [System.Collections.Generic.List[object]]::new()
    $checks.Add((New-BoostLabVerificationCheck `
        -Name 'settings.dat backup' `
        -Expected 'Verified backup present before mutation' `
        -Actual $(if ([bool]$BackupResult.Success) { [string]$BackupResult.BackupPath } else { [string]$BackupResult.Message }) `
        -Status $(if ([bool]$BackupResult.Success) { 'Passed' } else { 'Failed' }) `
        -Message ([string]$BackupResult.Message)))
    $checks.Add((New-BoostLabVerificationCheck `
        -Name 'settings.dat after Apply' `
        -Expected 'Present' `
        -Actual $(if (-not [bool]$FileState.ReadSucceeded) { 'Unknown' } elseif ([bool]$FileState.Exists) { 'Present' } else { 'Absent' }) `
        -Status $(if (-not [bool]$FileState.ReadSucceeded) { 'Warning' } elseif ([bool]$FileState.Exists) { 'Passed' } else { 'Failed' }) `
        -Message ([string]$FileState.Message)))

    foreach ($definition in $script:BoostLabNotepadExpectedValues) {
        $state = @($RegistryStates | Where-Object { $_.Name -eq $definition.Name }) | Select-Object -First 1
        $status = if ($null -eq $state -or -not [bool]$state.ReadSucceeded) {
            'Warning'
        }
        elseif (-not [bool]$state.Exists -or [string]$state.DisplayValue -ne [string]$definition.Expected) {
            'Failed'
        }
        else {
            'Passed'
        }
        $actual = if ($null -eq $state) { 'Unknown' } else { [string]$state.DisplayValue }
        $message = if ($null -eq $state) { 'Registry value was not captured.' } else { [string]$state.Message }
        $checks.Add((New-BoostLabVerificationCheck `
            -Name "Notepad LocalState | $($definition.Name)" `
            -Expected ([string]$definition.Expected) `
            -Actual $actual `
            -Status $status `
            -Message $message))
    }

    $statuses = @($checks | ForEach-Object { $_.Status })
    $overall = if ('Failed' -in $statuses) { 'Failed' } elseif ('Warning' -in $statuses) { 'Warning' } else { 'Passed' }
    New-BoostLabVerificationResult `
        -ToolId 'notepad-settings' `
        -ToolTitle 'Notepad Settings' `
        -Action 'Apply' `
        -Status $overall `
        -ExpectedState ([pscustomobject]@{ NotepadSettings = 'Approved OpenFile, GhostFile, and RewriteEnabled values present' }) `
        -DetectedState ([pscustomobject]@{ NotepadSettings = "$(@($checks | Where-Object Status -eq 'Passed').Count) passed, $(@($checks | Where-Object Status -eq 'Warning').Count) warning, $(@($checks | Where-Object Status -eq 'Failed').Count) failed" }) `
        -Checks $checks.ToArray() `
        -Message $(if ($overall -eq 'Passed') { 'Notepad settings verified.' } elseif ($overall -eq 'Warning') { 'Notepad settings were applied, but some verification was unavailable.' } else { 'Notepad settings verification failed.' })
}

function New-BoostLabNotepadDefaultVerification {
    param(
        [Parameter(Mandatory)][object]$FileState,
        [AllowNull()][object]$BackupResult,
        [Parameter(Mandatory)][bool]$WasInitiallyPresent
    )

    $checks = [System.Collections.Generic.List[object]]::new()
    if ($WasInitiallyPresent) {
        $checks.Add((New-BoostLabVerificationCheck `
            -Name 'settings.dat backup' `
            -Expected 'Verified backup present before deletion' `
            -Actual $(if ($null -ne $BackupResult -and [bool]$BackupResult.Success) { [string]$BackupResult.BackupPath } else { 'Unavailable' }) `
            -Status $(if ($null -ne $BackupResult -and [bool]$BackupResult.Success) { 'Passed' } else { 'Failed' }) `
            -Message $(if ($null -eq $BackupResult) { 'Backup result is unavailable.' } else { [string]$BackupResult.Message })))
    }
    $fileStatus = if (-not [bool]$FileState.ReadSucceeded) { 'Warning' } elseif ([bool]$FileState.Exists) { 'Failed' } else { 'Passed' }
    $checks.Add((New-BoostLabVerificationCheck `
        -Name 'settings.dat after Default' `
        -Expected 'Absent' `
        -Actual $(if (-not [bool]$FileState.ReadSucceeded) { 'Unknown' } elseif ([bool]$FileState.Exists) { 'Present' } else { 'Absent' }) `
        -Status $fileStatus `
        -Message ([string]$FileState.Message)))

    $statuses = @($checks | ForEach-Object { $_.Status })
    $overall = if ('Failed' -in $statuses) { 'Failed' } elseif ('Warning' -in $statuses) { 'Warning' } else { 'Passed' }
    New-BoostLabVerificationResult `
        -ToolId 'notepad-settings' `
        -ToolTitle 'Notepad Settings' `
        -Action 'Default' `
        -Status $overall `
        -ExpectedState ([pscustomobject]@{ NotepadSettings = 'settings.dat absent' }) `
        -DetectedState ([pscustomobject]@{ NotepadSettings = if (-not [bool]$FileState.ReadSucceeded) { 'Unknown' } elseif ([bool]$FileState.Exists) { 'Present' } else { 'Absent' } }) `
        -Checks $checks.ToArray() `
        -Message $(if ($overall -eq 'Passed') { 'Notepad default state verified.' } elseif ($overall -eq 'Warning') { 'Notepad Default completed, but verification was unavailable.' } else { 'Notepad Default verification failed.' })
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
        Applicable = $runtimeSupported -and $settingsDatExists
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
            'The source-targeted settings.dat is absent. Apply is not applicable; Default is already satisfied.'
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
        Status = if (-not [bool]$state.ReadSucceeded) { 'Unavailable' } elseif ([bool]$state.Exists) { 'settings.dat present' } else { 'Default' }
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
        [scriptblock]$DirectoryTester = { param($Path) Test-Path -LiteralPath $Path -PathType Container },
        [scriptblock]$FileStateReader = { param($Path) Get-BoostLabNotepadFileState -Path $Path },
        [scriptblock]$BackupWriter = { param($SourcePath, $BackupPath) Backup-BoostLabNotepadSettingsFile -SourcePath $SourcePath -BackupPath $BackupPath },
        [scriptblock]$StateWriter = { param($State, $ManifestPath) Save-BoostLabNotepadState -State $State -ManifestPath $ManifestPath },
        [scriptblock]$RegistryFileWriter = { param($Path, $Content) Set-Content -LiteralPath $Path -Value $Content -Force -ErrorAction Stop },
        [scriptblock]$RegistryCommandInvoker = { param($Operation, $Arguments, $Root) Invoke-BoostLabNotepadRegistryCommand -Operation $Operation -Arguments $Arguments -SystemRoot $Root },
        [scriptblock]$RegistryReader = { param($Name) Get-BoostLabNotepadRegistryValue -Name $Name },
        [scriptblock]$FileRemover = { param($Path) Remove-Item -LiteralPath $Path -Force -ErrorAction Stop },
        [string]$LocalAppData = $env:LocalAppData,
        [string]$SystemRoot = $env:SystemRoot,
        [string]$ProgramData = $env:ProgramData
    )

    if (-not $Confirmed) {
        return New-BoostLabNotepadResult -Success $false -Action $ActionName -Message 'Explicit confirmation is required.' -Cancelled $true
    }
    if (-not (& $AdministratorChecker)) {
        return New-BoostLabNotepadResult -Success $false -Action $ActionName -Message 'Administrator rights are required.'
    }

    $paths = Get-BoostLabNotepadPaths -LocalAppData $LocalAppData -SystemRoot $SystemRoot -ProgramData $ProgramData
    if (-not (Test-BoostLabNotepadSettingsPath -Path $paths.SettingsDatPath -LocalAppData $LocalAppData)) {
        return New-BoostLabNotepadResult -Success $false -Action $ActionName -Message 'The Notepad settings.dat path is outside the approved target.'
    }

    $initialState = & $FileStateReader $paths.SettingsDatPath
    if ($null -eq $initialState -or -not [bool]$initialState.ReadSucceeded) {
        $message = if ($null -eq $initialState) { 'settings.dat state reader returned no result.' } else { [string]$initialState.Message }
        $verification = New-BoostLabNotepadFailureVerification -Action $ActionName -Message $message
        return New-BoostLabNotepadResult -Success $false -Action $ActionName -Message $message -VerificationResult $verification
    }

    $packageDirectoryExists = [bool](& $DirectoryTester $paths.PackageDirectoryPath)
    if (-not [bool]$initialState.Exists) {
        if ($ActionName -eq 'Apply') {
            return New-BoostLabNotepadNotApplicableResult `
                -Action $ActionName `
                -Paths $paths `
                -PackageDirectoryExists $packageDirectoryExists
        }

        $verificationResult = New-BoostLabNotepadDefaultVerification `
            -FileState $initialState `
            -BackupResult $null `
            -WasInitiallyPresent $false
        $compatibilityMessage = 'No action was needed because the source-targeted Notepad settings.dat is already absent.'
        $data = [pscustomobject]@{
            CommandStatus = 'Already default'
            VerificationStatus = $verificationResult.Status
            CompatibilityStatus = 'Default already satisfied'
            CompatibilityMessage = 'This system may be using classic Notepad or a Notepad build that does not expose the source-targeted settings.dat.'
            ExpectedNotepadSettingsState = 'settings.dat absent'
            DetectedNotepadSettingsState = 'settings.dat absent'
            SettingsDatPath = $paths.SettingsDatPath
            NotepadPackageDirectoryPath = $paths.PackageDirectoryPath
            NotepadPackageDirectoryExists = $packageDirectoryExists
            SettingsDatExists = $false
            ChangesExecuted = $false
            BackupStatus = 'Not required because settings.dat was already absent.'
            BackupPath = ''
            OriginalSha256 = $null
            DetectedSha256 = $null
            ProcessActions = @('None; Default was already satisfied before process handling.')
            HiveOperations = @()
            RegistryValuesChecked = @()
            FileDisposition = 'No changes executed; settings.dat was already absent.'
            Warnings = @()
            CompletedAt = Get-Date
        }
        return New-BoostLabNotepadResult `
            -Success $true `
            -Action $ActionName `
            -Message $compatibilityMessage `
            -Data $data `
            -VerificationResult $verificationResult
    }

    $processResult = & $ProcessStopper
    if ($null -eq $processResult -or -not [bool]$processResult.Success) {
        $message = if ($null -eq $processResult) { 'Notepad process handling returned no result.' } else { [string]$processResult.Message }
        $verification = New-BoostLabNotepadFailureVerification -Action $ActionName -Message $message
        return New-BoostLabNotepadResult -Success $false -Action $ActionName -Message $message -VerificationResult $verification
    }
    & $DelayInvoker 2

    $backupResult = $null
    $backupResult = & $BackupWriter $paths.SettingsDatPath $paths.BackupPath
    if ($null -eq $backupResult -or -not [bool]$backupResult.Success) {
        $message = if ($null -eq $backupResult) { 'settings.dat backup returned no result.' } else { "settings.dat backup failed: $($backupResult.Message)" }
        $verification = New-BoostLabNotepadFailureVerification -Action $ActionName -Message $message
        return New-BoostLabNotepadResult -Success $false -Action $ActionName -Message $message -VerificationResult $verification
    }

    $stateRecord = [ordered]@{
        ToolId = 'notepad-settings'
        Action = $ActionName
        TargetPath = $paths.SettingsDatPath
        OriginalExisted = [bool]$initialState.Exists
        OriginalSha256 = $initialState.Sha256
        OriginalLength = $initialState.Length
        BackupPath = if ($null -ne $backupResult) { $backupResult.BackupPath } else { $null }
        BackupSha256 = if ($null -ne $backupResult) { $backupResult.Sha256 } else { $null }
        BackupVerified = $null -ne $backupResult -and [bool]$backupResult.Success
        BoostLabOwnsTargetFile = $false
        Status = 'Pending'
        CapturedAt = Get-Date
    }
    try {
        & $StateWriter ([pscustomobject]$stateRecord) $paths.ManifestPath
    }
    catch {
        $message = "Notepad state record could not be saved: $($_.Exception.Message)"
        $verification = New-BoostLabNotepadFailureVerification -Action $ActionName -Message $message
        return New-BoostLabNotepadResult -Success $false -Action $ActionName -Message $message -VerificationResult $verification
    }

    $registryStates = @()
    $hiveOperations = [System.Collections.Generic.List[string]]::new()
    try {
        if ($ActionName -eq 'Apply') {
            & $RegistryFileWriter $paths.RegistryFilePath $script:BoostLabNotepadRegistryFileContent
            $hiveLoaded = $false
            try {
                & $RegistryCommandInvoker 'load' @('HKLM\Settings', $paths.SettingsDatPath) $SystemRoot | Out-Null
                $hiveLoaded = $true
                $hiveOperations.Add('Loaded HKLM\Settings from Notepad settings.dat.')
                & $RegistryCommandInvoker 'import' @($paths.RegistryFilePath) $SystemRoot | Out-Null
                $hiveOperations.Add('Imported the approved notepadsettings.reg values.')
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
            }
            finally {
                if ($hiveLoaded) {
                    [gc]::Collect()
                    & $DelayInvoker 2
                    & $RegistryCommandInvoker 'unload' @('HKLM\Settings') $SystemRoot | Out-Null
                    $hiveOperations.Add('Unloaded HKLM\Settings.')
                }
            }

            $detectedFileState = & $FileStateReader $paths.SettingsDatPath
            $verificationResult = New-BoostLabNotepadApplyVerification `
                -RegistryStates @($registryStates) `
                -FileState $detectedFileState `
                -BackupResult $backupResult
            $success = $verificationResult.Status -ne 'Failed'
            $message = if ($success) { 'Notepad settings applied.' } else { 'Notepad settings were applied, but verification failed.' }
            $stateRecord['Status'] = if ($success) { 'Completed' } else { 'VerificationFailed' }
            $stateRecord['CompletedAt'] = Get-Date
            $stateRecord['DetectedSha256'] = $detectedFileState.Sha256
            & $StateWriter ([pscustomobject]$stateRecord) $paths.ManifestPath
            $data = [pscustomobject]@{
                CommandStatus = if ($success) { 'Completed' } else { 'Completed with verification failure' }
                VerificationStatus = $verificationResult.Status
                ExpectedNotepadSettingsState = 'Approved OpenFile, GhostFile, and RewriteEnabled values present'
                DetectedNotepadSettingsState = $verificationResult.DetectedState.NotepadSettings
                SettingsDatPath = $paths.SettingsDatPath
                NotepadPackageDirectoryPath = $paths.PackageDirectoryPath
                NotepadPackageDirectoryExists = $packageDirectoryExists
                SettingsDatExists = [bool]$detectedFileState.Exists
                ChangesExecuted = $true
                BackupStatus = [string]$backupResult.Message
                BackupPath = [string]$backupResult.BackupPath
                OriginalSha256 = $initialState.Sha256
                DetectedSha256 = $detectedFileState.Sha256
                ProcessActions = @([string]$processResult.Message)
                HiveOperations = $hiveOperations.ToArray()
                RegistryValuesChecked = @($registryStates | ForEach-Object { "$($_.Name): $($_.DisplayValue)" })
                FileDisposition = 'settings.dat retained and updated through the mounted hive.'
                Warnings = @()
                CompletedAt = Get-Date
            }
            return New-BoostLabNotepadResult -Success $success -Action $ActionName -Message $message -Data $data -VerificationResult $verificationResult
        }

        if ([bool]$initialState.Exists) {
            & $FileRemover $paths.SettingsDatPath
        }
        $detectedFileState = & $FileStateReader $paths.SettingsDatPath
        $verificationResult = New-BoostLabNotepadDefaultVerification `
            -FileState $detectedFileState `
            -BackupResult $backupResult `
            -WasInitiallyPresent ([bool]$initialState.Exists)
        $success = $verificationResult.Status -ne 'Failed'
        $message = if (-not [bool]$initialState.Exists -and $success) {
            'Notepad settings were already default.'
        }
        elseif ($success) {
            'Notepad settings restored to default.'
        }
        else {
            'Notepad Default completed, but verification failed.'
        }
        $stateRecord['Status'] = if ($success) { 'Completed' } else { 'VerificationFailed' }
        $stateRecord['CompletedAt'] = Get-Date
        $stateRecord['DetectedExists'] = $detectedFileState.Exists
        & $StateWriter ([pscustomobject]$stateRecord) $paths.ManifestPath
        $data = [pscustomobject]@{
            CommandStatus = if (-not [bool]$initialState.Exists) { 'Already default' } elseif ($success) { 'Completed' } else { 'Completed with verification failure' }
            VerificationStatus = $verificationResult.Status
            ExpectedNotepadSettingsState = 'settings.dat absent'
            DetectedNotepadSettingsState = $verificationResult.DetectedState.NotepadSettings
            SettingsDatPath = $paths.SettingsDatPath
            NotepadPackageDirectoryPath = $paths.PackageDirectoryPath
            NotepadPackageDirectoryExists = $packageDirectoryExists
            SettingsDatExists = [bool]$detectedFileState.Exists
            ChangesExecuted = [bool]$initialState.Exists
            BackupStatus = if ($null -eq $backupResult) { 'Not required because settings.dat was already absent.' } else { [string]$backupResult.Message }
            BackupPath = if ($null -eq $backupResult) { '' } else { [string]$backupResult.BackupPath }
            OriginalSha256 = $initialState.Sha256
            DetectedSha256 = $detectedFileState.Sha256
            ProcessActions = @([string]$processResult.Message)
            HiveOperations = @()
            RegistryValuesChecked = @()
            FileDisposition = if ([bool]$initialState.Exists) { 'Deleted only the approved Notepad settings.dat after backup.' } else { 'No file deleted; settings.dat was already absent.' }
            Warnings = @()
            CompletedAt = Get-Date
        }
        return New-BoostLabNotepadResult -Success $success -Action $ActionName -Message $message -Data $data -VerificationResult $verificationResult
    }
    catch {
        $message = $_.Exception.Message
        $stateRecord['Status'] = 'Failed'
        $stateRecord['Error'] = $message
        $stateRecord['CompletedAt'] = Get-Date
        try { & $StateWriter ([pscustomobject]$stateRecord) $paths.ManifestPath } catch {}
        $verificationResult = New-BoostLabNotepadFailureVerification -Action $ActionName -Message $message
        $data = [pscustomobject]@{
            CommandStatus = 'Failed'
            VerificationStatus = 'Failed'
            ExpectedNotepadSettingsState = if ($ActionName -eq 'Apply') { 'Approved values present' } else { 'settings.dat absent' }
            DetectedNotepadSettingsState = 'Operation failed'
            SettingsDatPath = $paths.SettingsDatPath
            NotepadPackageDirectoryPath = $paths.PackageDirectoryPath
            NotepadPackageDirectoryExists = $packageDirectoryExists
            SettingsDatExists = $null
            ChangesExecuted = $true
            BackupStatus = if ($null -eq $backupResult) { 'Not available' } else { [string]$backupResult.Message }
            BackupPath = if ($null -eq $backupResult) { '' } else { [string]$backupResult.BackupPath }
            OriginalSha256 = $initialState.Sha256
            DetectedSha256 = $null
            ProcessActions = @([string]$processResult.Message)
            HiveOperations = $hiveOperations.ToArray()
            RegistryValuesChecked = @($registryStates | ForEach-Object { "$($_.Name): $($_.DisplayValue)" })
            FileDisposition = 'Operation stopped after an error.'
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
