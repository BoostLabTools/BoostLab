Set-StrictMode -Version Latest

$verificationModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1'
Import-Module -Name $verificationModulePath -Scope Local -ErrorAction Stop
$sourceToleratedOutcomeModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\SourceToleratedOutcomes.psm1'
if (-not (Get-Command -Name 'New-BoostLabSourceToleratedOutcomeNote' -ErrorAction SilentlyContinue)) {
    Import-Module -Name $sourceToleratedOutcomeModulePath -Scope Local -Force -ErrorAction Stop
}

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
$script:BoostLabNotepadHiveMountPath = 'HKLM:\Settings'
$script:BoostLabNotepadHiveRegPath = 'HKLM\Settings'
$script:BoostLabNotepadHiveLocalStatePath = 'HKLM:\Settings\LocalState'

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
        [Parameter(Mandatory)][ValidateSet('load', 'import', 'unload', 'query')][string]$Operation,
        [Parameter(Mandatory)][string[]]$Arguments,
        [string]$SystemRoot = $env:SystemRoot
    )

    $regPath = Join-Path $SystemRoot 'System32\reg.exe'
    $output = @(& $regPath $Operation @Arguments 2>&1)
    $exitCode = if ($null -eq $LASTEXITCODE) { $null } else { [int]$LASTEXITCODE }
    return [pscustomobject]@{
        Success = ($null -ne $exitCode -and $exitCode -eq 0)
        Operation = $Operation
        ExitCode = $exitCode
        Output = $output
        StandardOutput = @($output)
        StandardError = @()
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

function Test-BoostLabNotepadByteDisplay {
    param([AllowNull()][object]$Value)

    return [bool](ConvertTo-BoostLabNotepadNormalizedByteDisplay -Value $Value).Success
}

function ConvertTo-BoostLabNotepadNormalizedByteDisplay {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) {
        return [pscustomobject]@{
            Success = $false
            Raw = ''
            Normalized = ''
            Bytes = @()
            Message = 'Byte value is null.'
        }
    }

    if ($Value -is [byte[]]) {
        $bytes = @($Value | ForEach-Object { $_.ToString('x2') })
        return [pscustomobject]@{
            Success = $true
            Raw = (@($bytes) -join ',')
            Normalized = (@($bytes) -join ',')
            Bytes = @($bytes)
            Message = 'Byte value came from a byte array.'
        }
    }

    $raw = ([string]$Value).Trim()
    $compact = $raw -replace '[\s,]', ''
    if ([string]::IsNullOrWhiteSpace($compact)) {
        return [pscustomobject]@{
            Success = $false
            Raw = $raw
            Normalized = ''
            Bytes = @()
            Message = 'Byte value is empty after removing separators.'
        }
    }
    if ($compact -notmatch '^(?i)[0-9a-f]+$' -or ($compact.Length % 2) -ne 0) {
        return [pscustomobject]@{
            Success = $false
            Raw = $raw
            Normalized = ''
            Bytes = @()
            Message = 'Byte value is not valid even-length hexadecimal data.'
        }
    }

    $bytes = for ($index = 0; $index -lt $compact.Length; $index += 2) {
        $compact.Substring($index, 2).ToLowerInvariant()
    }
    return [pscustomobject]@{
        Success = $true
        Raw = $raw
        Normalized = (@($bytes) -join ',')
        Bytes = @($bytes)
        Message = 'Byte value was normalized from text.'
    }
}

function Compare-BoostLabNotepadByteDisplay {
    param(
        [AllowNull()][object]$Expected,
        [AllowNull()][object]$Actual
    )

    $expectedBytes = ConvertTo-BoostLabNotepadNormalizedByteDisplay -Value $Expected
    $actualBytes = ConvertTo-BoostLabNotepadNormalizedByteDisplay -Value $Actual
    $succeeded = [bool]$expectedBytes.Success -and [bool]$actualBytes.Success -and ([string]$expectedBytes.Normalized -eq [string]$actualBytes.Normalized)
    $message = if (-not [bool]$expectedBytes.Success) {
        "Expected bytes could not be parsed: $($expectedBytes.Message)"
    }
    elseif (-not [bool]$actualBytes.Success) {
        "Actual bytes could not be parsed: $($actualBytes.Message)"
    }
    elseif ($succeeded) {
        'Expected and actual bytes match after normalization.'
    }
    else {
        'Expected and actual bytes differ after normalization.'
    }

    [pscustomobject]@{
        ExpectedBytesRaw = [string]$Expected
        ActualBytesRaw = [string]$Actual
        ExpectedBytesNormalized = [string]$expectedBytes.Normalized
        ActualBytesNormalized = [string]$actualBytes.Normalized
        ByteComparisonSucceeded = $succeeded
        ExpectedBytesParsed = [bool]$expectedBytes.Success
        ActualBytesParsed = [bool]$actualBytes.Success
        Message = $message
    }
}

function Add-BoostLabNotepadByteComparisonDetails {
    param(
        [Parameter(Mandatory)][object]$State,
        [Parameter(Mandatory)][string]$Expected
    )

    $comparison = Compare-BoostLabNotepadByteDisplay -Expected $Expected -Actual ([string]$State.DisplayValue)
    $State | Add-Member -NotePropertyName 'ExpectedBytesRaw' -NotePropertyValue ([string]$comparison.ExpectedBytesRaw) -Force
    $State | Add-Member -NotePropertyName 'ActualBytesRaw' -NotePropertyValue ([string]$comparison.ActualBytesRaw) -Force
    $State | Add-Member -NotePropertyName 'ExpectedBytesNormalized' -NotePropertyValue ([string]$comparison.ExpectedBytesNormalized) -Force
    $State | Add-Member -NotePropertyName 'ActualBytesNormalized' -NotePropertyValue ([string]$comparison.ActualBytesNormalized) -Force
    $State | Add-Member -NotePropertyName 'ByteComparisonSucceeded' -NotePropertyValue ([bool]$comparison.ByteComparisonSucceeded) -Force
    $State | Add-Member -NotePropertyName 'ByteComparisonMessage' -NotePropertyValue ([string]$comparison.Message) -Force
    return $comparison
}

function ConvertFrom-BoostLabNotepadRegQueryOutput {
    param(
        [Parameter(Mandatory)][string]$Output,
        [Parameter(Mandatory)][string]$Name
    )

    $lines = @($Output -split "\r?\n")
    $valueLineIndex = -1
    $valueType = 'Unknown'
    $dataParts = [System.Collections.Generic.List[string]]::new()

    for ($index = 0; $index -lt $lines.Count; $index++) {
        $line = [string]$lines[$index]
        if ($line -match ('^\s*{0}\s+(?<Type>\S+)\s*(?<Data>.*)$' -f [regex]::Escape($Name))) {
            $valueLineIndex = $index
            $valueType = [string]$Matches.Type
            if (-not [string]::IsNullOrWhiteSpace([string]$Matches.Data)) {
                $dataParts.Add([string]$Matches.Data)
            }
            break
        }
    }

    if ($valueLineIndex -lt 0) {
        return [pscustomobject]@{
            ReadSucceeded = $true
            Exists = $false
            Name = $Name
            ValueType = $null
            DisplayValue = 'Absent'
            Message = 'reg query did not return the requested value.'
            ReadMethod = 'reg query'
        }
    }

    for ($index = $valueLineIndex + 1; $index -lt $lines.Count; $index++) {
        $line = [string]$lines[$index]
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        if ($line -match '^\s*HKEY_' -or $line -match '^\s*\S+\s+REG_\S+') {
            break
        }
        $dataParts.Add($line.Trim())
    }

    $dataText = (@($dataParts.ToArray()) -join ' ').Trim()
    $byteMatches = @([regex]::Matches($dataText, '(?i)\b[0-9a-f]{2}\b') | ForEach-Object { $_.Value.ToLowerInvariant() })
    $displayValue = if ($byteMatches.Count -gt 0) {
        $byteMatches -join ','
    }
    else {
        $dataText
    }

    [pscustomobject]@{
        ReadSucceeded = $true
        Exists = $true
        Name = $Name
        ValueType = $valueType
        DisplayValue = $displayValue
        Message = 'Registry value detected by reg query at HKLM:\Settings\LocalState.'
        ReadMethod = 'reg query'
    }
}

function Get-BoostLabNotepadCommandText {
    param(
        [Parameter(Mandatory)][string]$Operation,
        [Parameter(Mandatory)][string[]]$Arguments
    )

    $quoted = @($Arguments | ForEach-Object {
        if ([string]$_ -match '\s') {
            '"{0}"' -f [string]$_
        }
        else {
            [string]$_
        }
    })
    "reg $Operation $($quoted -join ' ')".Trim()
}

function Test-BoostLabNotepadNativeSuccessOutput {
    param([AllowNull()][string]$NativeOutput)

    if ([string]::IsNullOrWhiteSpace($NativeOutput)) {
        return $false
    }
    return ($NativeOutput -match '(?i)\bthe operation completed successfully\.?\b')
}

function ConvertTo-BoostLabNotepadHiveOperation {
    param(
        [Parameter(Mandatory)][string]$Stage,
        [Parameter(Mandatory)][string]$Operation,
        [Parameter(Mandatory)][string[]]$Arguments,
        [AllowNull()][object]$Result = $null,
        [AllowNull()][string]$ErrorMessage = ''
    )

    $exitCode = $null
    $exitCodeCaptured = $false
    $output = [System.Collections.Generic.List[string]]::new()
    $standardOutput = [System.Collections.Generic.List[string]]::new()
    $standardError = [System.Collections.Generic.List[string]]::new()
    if ($null -ne $Result) {
        $exitCodeProperty = $Result.PSObject.Properties['ExitCode']
        if ($null -ne $exitCodeProperty -and $null -ne $exitCodeProperty.Value -and -not [string]::IsNullOrWhiteSpace([string]$exitCodeProperty.Value)) {
            $parsedExitCode = 0
            if ([int]::TryParse([string]$exitCodeProperty.Value, [ref]$parsedExitCode)) {
                $exitCode = $parsedExitCode
                $exitCodeCaptured = $true
            }
        }
        if ($null -ne $Result.PSObject.Properties['Output']) {
            foreach ($line in @($Result.Output)) {
                if ($null -ne $line) {
                    $output.Add([string]$line)
                }
            }
        }
        if ($null -ne $Result.PSObject.Properties['StandardOutput']) {
            foreach ($line in @($Result.StandardOutput)) {
                if ($null -ne $line) {
                    $standardOutput.Add([string]$line)
                }
            }
        }
        if ($null -ne $Result.PSObject.Properties['StandardError']) {
            foreach ($line in @($Result.StandardError)) {
                if ($null -ne $line) {
                    $standardError.Add([string]$line)
                }
            }
        }
        if ($null -ne $Result.PSObject.Properties['NativeOutput']) {
            foreach ($line in @($Result.NativeOutput)) {
                if ($null -ne $line) {
                    $output.Add([string]$line)
                }
            }
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($ErrorMessage)) {
        $standardError.Add($ErrorMessage)
    }
    $nativeLines = [System.Collections.Generic.List[string]]::new()
    foreach ($line in @($output.ToArray() + $standardOutput.ToArray() + $standardError.ToArray())) {
        if (-not [string]::IsNullOrWhiteSpace([string]$line)) {
            $nativeLines.Add([string]$line)
        }
    }
    $outputText = (@($nativeLines.ToArray()) | Select-Object -Unique) -join [Environment]::NewLine
    $standardOutputText = (@($standardOutput.ToArray()) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }) -join [Environment]::NewLine
    if ([string]::IsNullOrWhiteSpace($standardOutputText) -and $output.Count -gt 0) {
        $standardOutputText = (@($output.ToArray()) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }) -join [Environment]::NewLine
    }
    $standardErrorText = (@($standardError.ToArray()) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }) -join [Environment]::NewLine
    $exitCodeSuccess = ($exitCodeCaptured -and $exitCode -eq 0)
    $recoverableMissingExitCode = (
        -not $exitCodeCaptured -and
        $Stage -eq 'ImportNotepadSettingsPayload' -and
        (Test-BoostLabNotepadNativeSuccessOutput -NativeOutput $outputText)
    )
    $success = ($exitCodeSuccess -or $recoverableMissingExitCode)
    $failureKind = if ($exitCodeSuccess) {
        ''
    }
    elseif ($recoverableMissingExitCode) {
        'NativeExitCodeMissingWithSuccessOutput'
    }
    elseif (-not $exitCodeCaptured) {
        'NativeExitCodeMissing'
    }
    elseif ($exitCode -ne 0) {
        'NativeExitCodeNonZero'
    }
    else {
        'NativeCommandFailed'
    }
    $message = if ($exitCodeSuccess) {
        "$Stage completed."
    }
    elseif ($recoverableMissingExitCode) {
        "$Stage did not return a native exit code, but reg.exe output indicated success; mounted hive values must verify before the import is accepted."
    }
    elseif ($failureKind -eq 'NativeExitCodeMissing') {
        $diagnosticOutput = if ([string]::IsNullOrWhiteSpace($outputText)) { 'No native output was captured.' } else { "Native output: $outputText" }
        "$Stage failed because reg.exe did not return an exit code (NativeExitCodeMissing). $diagnosticOutput"
    }
    elseif (-not [string]::IsNullOrWhiteSpace($outputText)) {
        $outputText
    }
    else {
        "$Stage failed with exit code $exitCode."
    }

    [pscustomobject]@{
        Stage = $Stage
        Executable = 'reg.exe'
        Operation = $Operation
        Arguments = @($Arguments)
        CommandText = Get-BoostLabNotepadCommandText -Operation $Operation -Arguments @($Arguments)
        ExitCode = $exitCode
        ExitCodeCaptured = $exitCodeCaptured
        Success = $success
        StandardOutput = $standardOutputText
        StandardError = $standardErrorText
        NativeOutput = $outputText
        FailureKind = $failureKind
        Message = $message
        RecoveryAttempted = $recoverableMissingExitCode
        RecoveryReason = if ($recoverableMissingExitCode) { 'NativeExitCodeMissingWithSuccessOutput' } else { '' }
        RequiresPostImportVerification = $recoverableMissingExitCode
    }
}

function Invoke-BoostLabNotepadCheckedRegistryCommand {
    param(
        [Parameter(Mandatory)][string]$Stage,
        [Parameter(Mandatory)][string]$Operation,
        [Parameter(Mandatory)][string[]]$Arguments,
        [Parameter(Mandatory)][string]$SystemRoot,
        [scriptblock]$RegistryCommandInvoker
    )

    try {
        $result = & $RegistryCommandInvoker $Operation @($Arguments) $SystemRoot
        ConvertTo-BoostLabNotepadHiveOperation -Stage $Stage -Operation $Operation -Arguments @($Arguments) -Result $result
    }
    catch {
        ConvertTo-BoostLabNotepadHiveOperation -Stage $Stage -Operation $Operation -Arguments @($Arguments) -ErrorMessage $_.Exception.Message
    }
}

function Test-BoostLabNotepadAccessDeniedOutput {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value) {
        return $false
    }
    return ([string]$Value) -match '(?i)access\s+is\s+denied|0x5|denied'
}

function Get-BoostLabNotepadMountedHiveState {
    param(
        [scriptblock]$HiveMountReader = {
            [pscustomobject]@{
                Exists = Test-Path -LiteralPath $script:BoostLabNotepadHiveMountPath -PathType Container
                CanUnload = $true
                Message = 'HKLM:\Settings mount state detected.'
            }
        }
    )

    try {
        $results = @(& $HiveMountReader)
        if ($results.Count -eq 0 -or $null -eq $results[0]) {
            throw 'Hive mount reader returned no result.'
        }
        $state = $results[0]
        if ($null -eq $state.PSObject.Properties['Exists']) {
            $state | Add-Member -NotePropertyName 'Exists' -NotePropertyValue $false -Force
        }
        if ($null -eq $state.PSObject.Properties['CanUnload']) {
            $state | Add-Member -NotePropertyName 'CanUnload' -NotePropertyValue $true -Force
        }
        if ($null -eq $state.PSObject.Properties['Message']) {
            $state | Add-Member -NotePropertyName 'Message' -NotePropertyValue 'HKLM:\Settings mount state detected.' -Force
        }
        return $state
    }
    catch {
        [pscustomobject]@{
            Exists = $false
            CanUnload = $false
            Message = $_.Exception.Message
        }
    }
}

function Get-BoostLabNotepadHiveRegistryValue {
    param(
        [Parameter(Mandatory)][string]$Name,
        [scriptblock]$RegistryReader,
        [scriptblock]$RegistryCommandInvoker,
        [string]$SystemRoot
    )

    $providerState = $null
    if ($null -ne $RegistryReader) {
        $providerResults = @(& $RegistryReader $Name)
        if ($providerResults.Count -gt 0) {
            $providerState = $providerResults[0]
        }
    }

    if (
        $null -ne $providerState -and
        [bool]$providerState.ReadSucceeded -and
        [bool]$providerState.Exists -and
        (Test-BoostLabNotepadByteDisplay -Value $providerState.DisplayValue)
    ) {
        $providerState | Add-Member -NotePropertyName 'ReadMethod' -NotePropertyValue 'PowerShell registry provider' -Force
        return $providerState
    }

    $queryOperation = Invoke-BoostLabNotepadCheckedRegistryCommand `
        -Stage "QueryValue:$Name" `
        -Operation 'query' `
        -Arguments @('HKLM\Settings\LocalState', '/v', $Name) `
        -SystemRoot $SystemRoot `
        -RegistryCommandInvoker $RegistryCommandInvoker
    if ([bool]$queryOperation.Success) {
        $queryState = ConvertFrom-BoostLabNotepadRegQueryOutput -Output ([string]$queryOperation.NativeOutput) -Name $Name
        if ([bool]$queryState.Exists) {
            return $queryState
        }
    }

    if ($null -ne $providerState) {
        $providerState | Add-Member -NotePropertyName 'ReadMethod' -NotePropertyValue 'PowerShell registry provider; reg query fallback' -Force
        if (-not [bool]$queryOperation.Success) {
            $providerState | Add-Member -NotePropertyName 'FallbackMessage' -NotePropertyValue ([string]$queryOperation.Message) -Force
        }
        return $providerState
    }

    [pscustomobject]@{
        ReadSucceeded = [bool]$queryOperation.Success
        Exists = $false
        Name = $Name
        DisplayValue = if ([bool]$queryOperation.Success) { 'Absent' } else { 'Unknown' }
        Message = if ([bool]$queryOperation.Success) { 'Registry value is absent.' } else { [string]$queryOperation.Message }
        ReadMethod = 'reg query'
    }
}

function Invoke-BoostLabNotepadSettingsHiveImport {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string]$SettingsDatPath,
        [Parameter(Mandatory)][string]$RegistryFilePath,
        [Parameter(Mandatory)][string]$RegistryFileContent,
        [Parameter(Mandatory)][string]$SystemRoot,
        [scriptblock]$RegistryFileWriter,
        [scriptblock]$PathTester,
        [scriptblock]$RegistryCommandInvoker,
        [scriptblock]$RegistryReader,
        [scriptblock]$HiveMountReader,
        [scriptblock]$ProcessStopper,
        [scriptblock]$DelayInvoker,
        [int]$AccessDeniedRetryCount = 1
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()
    $hiveOperations = [System.Collections.Generic.List[object]]::new()
    $registryStates = [System.Collections.Generic.List[object]]::new()
    $hiveLoaded = $false
    $settingsDatExists = [bool](& $PathTester $SettingsDatPath 'Leaf')

    try {
        & $RegistryFileWriter $RegistryFilePath $RegistryFileContent | Out-Null
    }
    catch {
        $errors.Add("WriteRegFile failed: $($_.Exception.Message)")
    }
    if ($errors.Count -gt 0) {
        return [pscustomobject]@{
            Success = $false
            Message = "Notepad settings.dat hive import failed before hive load: $($errors.ToArray() -join ' ')"
            FinalStatusReason = 'RegFileWriteFailed'
            SettingsDatExists = $settingsDatExists
            HiveOperations = $hiveOperations.ToArray()
            RegistryValuesChecked = $registryStates.ToArray()
            Errors = $errors.ToArray()
            Warnings = $warnings.ToArray()
        }
    }

    if (-not $settingsDatExists) {
        $errors.Add("Microsoft Notepad settings.dat was not found: $SettingsDatPath")
        return [pscustomobject]@{
            Success = $false
            Message = 'Notepad settings.dat hive import failed: settings.dat is missing.'
            FinalStatusReason = 'SettingsDatMissing'
            SettingsDatExists = $false
            HiveOperations = $hiveOperations.ToArray()
            RegistryValuesChecked = $registryStates.ToArray()
            Errors = $errors.ToArray()
            Warnings = $warnings.ToArray()
        }
    }

    $mountedState = Get-BoostLabNotepadMountedHiveState -HiveMountReader $HiveMountReader
    if ([bool]$mountedState.Exists) {
        if (-not [bool]$mountedState.CanUnload) {
            $errors.Add("HKLM:\Settings is already mounted and cannot be safely unloaded before Notepad import: $($mountedState.Message)")
            return [pscustomobject]@{
                Success = $false
                Message = 'Notepad settings.dat hive import failed: HKLM:\Settings is already mounted.'
                FinalStatusReason = 'ExistingHiveMountBlocked'
                SettingsDatExists = $true
                HiveOperations = $hiveOperations.ToArray()
                RegistryValuesChecked = $registryStates.ToArray()
                Errors = $errors.ToArray()
                Warnings = $warnings.ToArray()
            }
        }

        $staleUnload = Invoke-BoostLabNotepadCheckedRegistryCommand `
            -Stage 'PreExistingHiveUnload' `
            -Operation 'unload' `
            -Arguments @($script:BoostLabNotepadHiveRegPath) `
            -SystemRoot $SystemRoot `
            -RegistryCommandInvoker $RegistryCommandInvoker
        $hiveOperations.Add($staleUnload)
        if (-not [bool]$staleUnload.Success) {
            $errors.Add("PreExistingHiveUnload failed: $($staleUnload.Message)")
            return [pscustomobject]@{
                Success = $false
                Message = 'Notepad settings.dat hive import failed: pre-existing HKLM:\Settings could not be unloaded.'
                FinalStatusReason = 'ExistingHiveUnloadFailed'
                SettingsDatExists = $true
                HiveOperations = $hiveOperations.ToArray()
                RegistryValuesChecked = $registryStates.ToArray()
                Errors = $errors.ToArray()
                Warnings = $warnings.ToArray()
            }
        }
        $warnings.Add('Pre-existing HKLM:\Settings mount was unloaded before Notepad settings.dat import.')
    }

    try {
        for ($attempt = 0; $attempt -le $AccessDeniedRetryCount; $attempt++) {
            $loadOperation = Invoke-BoostLabNotepadCheckedRegistryCommand `
                -Stage 'LoadSettingsHive' `
                -Operation 'load' `
                -Arguments @($script:BoostLabNotepadHiveRegPath, $SettingsDatPath) `
                -SystemRoot $SystemRoot `
                -RegistryCommandInvoker $RegistryCommandInvoker
            $loadOperation | Add-Member -NotePropertyName 'Attempt' -NotePropertyValue ($attempt + 1) -Force
            $hiveOperations.Add($loadOperation)
            if ([bool]$loadOperation.Success) {
                $hiveLoaded = $true
                break
            }

            if ($attempt -lt $AccessDeniedRetryCount -and (Test-BoostLabNotepadAccessDeniedOutput -Value $loadOperation.NativeOutput)) {
                $warnings.Add('reg load returned access denied; Notepad stop/delay retry was attempted.')
                & $ProcessStopper | Out-Null
                & $DelayInvoker 2
                continue
            }

            $errors.Add("LoadSettingsHive failed: $($loadOperation.Message)")
            $loadFailureMessage = "Notepad settings.dat hive import failed during reg load: $($errors.ToArray() -join ' ')"
            return [pscustomobject]@{
                Success = $false
                Message = $loadFailureMessage
                FinalStatusReason = 'HiveLoadFailed'
                SettingsDatExists = $true
                HiveOperations = $hiveOperations.ToArray()
                RegistryValuesChecked = $registryStates.ToArray()
                Errors = $errors.ToArray()
                Warnings = $warnings.ToArray()
            }
        }

        if (-not $hiveLoaded) {
            $errors.Add('LoadSettingsHive did not mount HKLM:\Settings.')
            $loadFailureMessage = "Notepad settings.dat hive import failed during reg load: $($errors.ToArray() -join ' ')"
            return [pscustomobject]@{
                Success = $false
                Message = $loadFailureMessage
                FinalStatusReason = 'HiveLoadFailed'
                SettingsDatExists = $true
                HiveOperations = $hiveOperations.ToArray()
                RegistryValuesChecked = $registryStates.ToArray()
                Errors = $errors.ToArray()
                Warnings = $warnings.ToArray()
            }
        }

        $importOperation = Invoke-BoostLabNotepadCheckedRegistryCommand `
            -Stage 'ImportNotepadSettingsPayload' `
            -Operation 'import' `
            -Arguments @($RegistryFilePath) `
            -SystemRoot $SystemRoot `
            -RegistryCommandInvoker $RegistryCommandInvoker
        $hiveOperations.Add($importOperation)
        if ([bool]$importOperation.RecoveryAttempted) {
            $warnings.Add('ImportNotepadSettingsPayload returned no native exit code but reported successful native output; mounted hive verification was required before accepting the import.')
        }
        if (-not [bool]$importOperation.Success) {
            $errors.Add("ImportNotepadSettingsPayload failed: $($importOperation.Message)")
        }
        else {
            foreach ($definition in $script:BoostLabNotepadExpectedValues) {
                $state = Get-BoostLabNotepadHiveRegistryValue `
                    -Name ([string]$definition.Name) `
                    -RegistryReader $RegistryReader `
                    -RegistryCommandInvoker $RegistryCommandInvoker `
                    -SystemRoot $SystemRoot
                $state | Add-Member -NotePropertyName 'Expected' -NotePropertyValue ([string]$definition.Expected) -Force
                $state | Add-Member -NotePropertyName 'Actual' -NotePropertyValue ([string]$state.DisplayValue) -Force
                $registryStates.Add($state)

                if (-not [bool]$state.ReadSucceeded) {
                    $errors.Add("$($definition.Name) could not be read before hive unload: $($state.Message)")
                    continue
                }
                if (-not [bool]$state.Exists) {
                    $errors.Add("$($definition.Name) was absent after Notepad settings import.")
                    continue
                }
                $byteComparison = Add-BoostLabNotepadByteComparisonDetails -State $state -Expected ([string]$definition.Expected)
                if (-not [bool]$byteComparison.ByteComparisonSucceeded) {
                    $errors.Add("$($definition.Name) mismatch after Notepad settings import. Expected $($definition.Expected) (normalized $($byteComparison.ExpectedBytesNormalized)), found $($state.DisplayValue) (normalized $($byteComparison.ActualBytesNormalized)). $($byteComparison.Message)")
                }
            }
        }
    }
    finally {
        if ($hiveLoaded) {
            [gc]::Collect()
            & $DelayInvoker 2
            $unloadOperation = Invoke-BoostLabNotepadCheckedRegistryCommand `
                -Stage 'UnloadSettingsHive' `
                -Operation 'unload' `
                -Arguments @($script:BoostLabNotepadHiveRegPath) `
                -SystemRoot $SystemRoot `
                -RegistryCommandInvoker $RegistryCommandInvoker
            $hiveOperations.Add($unloadOperation)
            if (-not [bool]$unloadOperation.Success) {
                $errors.Add("UnloadSettingsHive failed: $($unloadOperation.Message)")
            }
        }
    }

    $success = ($errors.Count -eq 0)
    $missingExitCodeOperation = @($hiveOperations.ToArray() | Where-Object { [string]$_.FailureKind -eq 'NativeExitCodeMissing' }) | Select-Object -First 1
    $recoverableExitCodeOperation = @($hiveOperations.ToArray() | Where-Object { [string]$_.FailureKind -eq 'NativeExitCodeMissingWithSuccessOutput' }) | Select-Object -First 1
    $failedImportOperation = @($hiveOperations.ToArray() | Where-Object { [string]$_.Stage -eq 'ImportNotepadSettingsPayload' -and -not [bool]$_.Success }) | Select-Object -First 1
    $finalStatusReason = if ($success) {
        if ($null -ne $recoverableExitCodeOperation) { 'NativeExitCodeMissingRecoveredByVerification' } else { 'HiveImportVerified' }
    }
    elseif ($null -ne $missingExitCodeOperation) {
        'NativeExitCodeMissing'
    }
    elseif ($null -ne $failedImportOperation) {
        'HiveImportFailed'
    }
    else {
        'HiveImportVerificationFailed'
    }
    [pscustomobject]@{
        Success = $success
        Message = if ($success -and $null -ne $recoverableExitCodeOperation) {
            'Notepad settings.dat hive payload import had a missing native exit code, but mounted hive verification passed.'
        }
        elseif ($success) {
            'Notepad settings.dat hive payload imported and verified.'
        }
        else {
            "Notepad settings.dat hive import failed: $($errors.ToArray() -join ' ')"
        }
        FinalStatusReason = $finalStatusReason
        SettingsDatExists = $true
        HiveOperations = $hiveOperations.ToArray()
        RegistryValuesChecked = $registryStates.ToArray()
        Errors = $errors.ToArray()
        Warnings = $warnings.ToArray()
        RecoveryAttempted = ($null -ne $recoverableExitCodeOperation)
        RecoveryReason = if ($null -ne $recoverableExitCodeOperation) { 'NativeExitCodeMissingWithSuccessOutput' } else { '' }
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
        [Parameter(Mandatory)][object]$HiveImportResult,
        [Parameter(Mandatory)][object]$FileState
    )

    $checks = [System.Collections.Generic.List[object]]::new()
    $checks.Add((New-BoostLabVerificationCheck `
        -Name 'settings.dat exists before Apply' `
        -Expected 'Present' `
        -Actual $(if ([bool]$HiveImportResult.SettingsDatExists) { 'Present' } else { 'Absent' }) `
        -Status $(if ([bool]$HiveImportResult.SettingsDatExists) { 'Passed' } else { 'Failed' }) `
        -Message $(if ([bool]$HiveImportResult.SettingsDatExists) { 'settings.dat was present before hive load.' } else { 'settings.dat was missing before hive load.' })))

    foreach ($operation in @($HiveImportResult.HiveOperations)) {
        $operationRecovered = [bool]$operation.RecoveryAttempted
        $loadAccessDeniedRecovered = (
            [bool]$HiveImportResult.Success -and
            [string]$operation.Stage -eq 'LoadSettingsHive' -and
            -not [bool]$operation.Success -and
            (Test-BoostLabNotepadAccessDeniedOutput -Value $operation.NativeOutput) -and
            @($HiveImportResult.HiveOperations | Where-Object { [string]$_.Stage -eq 'LoadSettingsHive' -and [bool]$_.Success }).Count -gt 0
        )
        $checks.Add((New-BoostLabVerificationCheck `
            -Name "Hive operation | $($operation.Stage)" `
            -Expected $(if ($operationRecovered) { 'Exit code 0 or mounted hive verification recovery' } elseif ($loadAccessDeniedRecovered) { 'Exit code 0 or bounded access-denied retry recovery' } else { 'Exit code 0' }) `
            -Actual $(if ($null -eq $operation.ExitCode) { 'No exit code' } else { "ExitCode=$($operation.ExitCode)" }) `
            -Status $(if (-not [bool]$operation.Success -and -not $loadAccessDeniedRecovered) { 'Failed' } else { 'Passed' }) `
            -Message ([string]$operation.Message)))
    }

    foreach ($definition in $script:BoostLabNotepadExpectedValues) {
        $state = @($HiveImportResult.RegistryValuesChecked | Where-Object { $_.Name -eq $definition.Name }) | Select-Object -First 1
        $byteComparison = $null
        if ($null -ne $state -and [bool]$state.ReadSucceeded -and [bool]$state.Exists) {
            if ($null -eq $state.PSObject.Properties['ByteComparisonSucceeded']) {
                $byteComparison = Add-BoostLabNotepadByteComparisonDetails -State $state -Expected ([string]$definition.Expected)
            }
            else {
                $byteComparison = [pscustomobject]@{
                    ExpectedBytesRaw = if ($null -eq $state.PSObject.Properties['ExpectedBytesRaw']) { [string]$definition.Expected } else { [string]$state.ExpectedBytesRaw }
                    ActualBytesRaw = if ($null -eq $state.PSObject.Properties['ActualBytesRaw']) { [string]$state.DisplayValue } else { [string]$state.ActualBytesRaw }
                    ExpectedBytesNormalized = if ($null -eq $state.PSObject.Properties['ExpectedBytesNormalized']) { '' } else { [string]$state.ExpectedBytesNormalized }
                    ActualBytesNormalized = if ($null -eq $state.PSObject.Properties['ActualBytesNormalized']) { '' } else { [string]$state.ActualBytesNormalized }
                    ByteComparisonSucceeded = [bool]$state.ByteComparisonSucceeded
                    Message = if ($null -eq $state.PSObject.Properties['ByteComparisonMessage']) { '' } else { [string]$state.ByteComparisonMessage }
                }
            }
        }
        $status = if ($null -eq $state -or -not [bool]$state.ReadSucceeded) {
            'Failed'
        }
        elseif (-not [bool]$state.Exists -or -not [bool]$byteComparison.ByteComparisonSucceeded) {
            'Failed'
        }
        else {
            'Passed'
        }
        $actual = if ($null -eq $state) { 'Not checked' } else { [string]$state.DisplayValue }
        $message = if ($null -eq $state) {
            'Registry value was not captured before hive unload.'
        }
        elseif ($null -ne $byteComparison) {
            "$([string]$state.Message) $([string]$byteComparison.Message)"
        }
        else {
            [string]$state.Message
        }
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
    $overall = if ('Failed' -in $statuses -or -not [bool]$HiveImportResult.Success) { 'Failed' } elseif ('Warning' -in $statuses) { 'Warning' } else { 'Passed' }
    New-BoostLabVerificationResult `
        -ToolId 'notepad-settings' `
        -ToolTitle 'Notepad Settings' `
        -Action 'Apply' `
        -Status $overall `
        -ExpectedState ([pscustomobject]@{ NotepadSettings = 'Source-defined Notepad settings imported, verified, and hive unloaded' }) `
        -DetectedState ([pscustomobject]@{ NotepadSettings = "$(@($checks | Where-Object Status -eq 'Passed').Count) passed, $(@($checks | Where-Object Status -eq 'Warning').Count) warning, $(@($checks | Where-Object Status -eq 'Failed').Count) failed" }) `
        -Checks $checks.ToArray() `
        -Message $(if ($overall -eq 'Passed') { 'Notepad settings verified.' } elseif ($overall -eq 'Warning') { 'Notepad settings imported, but verification included warnings.' } else { 'Notepad settings verification failed.' })
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
        [scriptblock]$RegistryFileWriter = { param($Path, $Content) Set-Content -LiteralPath $Path -Value $Content -Encoding Unicode -Force -ErrorAction Stop },
        [scriptblock]$RegistryCommandInvoker = { param($Operation, $Arguments, $Root) Invoke-BoostLabNotepadRegistryCommand -Operation $Operation -Arguments $Arguments -SystemRoot $Root },
        [scriptblock]$RegistryReader = { param($Name) Get-BoostLabNotepadRegistryValue -Name $Name },
        [scriptblock]$FileRemover = { param($Path) Invoke-BoostLabNotepadFileRemoval -Path $Path },
        [scriptblock]$PathTester = { param($Path, $PathType) Test-Path -LiteralPath $Path -PathType $PathType },
        [scriptblock]$HiveMountReader = { Get-BoostLabNotepadMountedHiveState },
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
            $hiveImportResult = Invoke-BoostLabNotepadSettingsHiveImport `
                -SettingsDatPath $paths.SettingsDatPath `
                -RegistryFilePath $paths.RegistryFilePath `
                -RegistryFileContent $script:BoostLabNotepadRegistryFileContent `
                -SystemRoot $SystemRoot `
                -RegistryFileWriter $RegistryFileWriter `
                -PathTester $PathTester `
                -RegistryCommandInvoker $RegistryCommandInvoker `
                -RegistryReader $RegistryReader `
                -HiveMountReader $HiveMountReader `
                -ProcessStopper $ProcessStopper `
                -DelayInvoker $DelayInvoker
            $detectedFileState = & $FileStateReader $paths.SettingsDatPath
            $verificationResult = New-BoostLabNotepadApplyVerification `
                -HiveImportResult $hiveImportResult `
                -FileState $detectedFileState
            $success = [bool]$hiveImportResult.Success -and $verificationResult.Status -ne 'Failed'
            $informationalNotes = [System.Collections.Generic.List[object]]::new()
            $severityWarnings = [System.Collections.Generic.List[string]]::new()
            foreach ($warning in @($hiveImportResult.Warnings)) {
                $warningText = [string]$warning
                if (
                    $success -and
                    [string]$verificationResult.Status -eq 'Passed' -and
                    [string]$hiveImportResult.FinalStatusReason -eq 'NativeExitCodeMissingRecoveredByVerification' -and
                    $warningText -like 'ImportNotepadSettingsPayload returned no native exit code*'
                ) {
                    $informationalNotes.Add(
                        (New-BoostLabSourceToleratedOutcomeNote `
                            -ToolId 'notepad-settings' `
                            -ReasonCode 'NativeExitCodeMissingRecoveredByVerification' `
                            -Message $warningText `
                            -Details ([pscustomobject]@{ Action = $ActionName; VerificationStatus = [string]$verificationResult.Status }))
                    )
                    continue
                }
                if (
                    $success -and
                    [string]$verificationResult.Status -eq 'Passed' -and
                    $warningText -like 'Pre-existing HKLM:\Settings mount was unloaded before Notepad settings.dat import.*'
                ) {
                    $informationalNotes.Add(
                        (New-BoostLabSourceToleratedOutcomeNote `
                            -ToolId 'notepad-settings' `
                            -ReasonCode 'PreExistingHiveMountRecovered' `
                            -Message $warningText `
                            -Details ([pscustomobject]@{ Action = $ActionName; VerificationStatus = [string]$verificationResult.Status }))
                    )
                    continue
                }
                if (
                    $success -and
                    [string]$verificationResult.Status -eq 'Passed' -and
                    $warningText -like 'reg load returned access denied; Notepad stop/delay retry was attempted.*'
                ) {
                    $informationalNotes.Add(
                        (New-BoostLabSourceToleratedOutcomeNote `
                            -ToolId 'notepad-settings' `
                            -ReasonCode 'HiveLoadAccessDeniedRecovered' `
                            -Message $warningText `
                            -Details ([pscustomobject]@{ Action = $ActionName; VerificationStatus = [string]$verificationResult.Status }))
                    )
                    continue
                }
                $severityWarnings.Add($warningText)
            }
            $completedWithWarnings = ($success -and ($verificationResult.Status -eq 'Warning' -or $severityWarnings.Count -gt 0))
            $message = if ($success -and $completedWithWarnings) {
                'Notepad settings Apply source sequence completed with warnings; mounted hive verification passed.'
            }
            elseif ($success -and $informationalNotes.Count -gt 0) {
                'Notepad settings Apply source sequence completed; expected informational recovery details were recorded.'
            }
            elseif ($success) {
                'Notepad settings Apply source sequence completed.'
            }
            else {
                [string]$hiveImportResult.Message
            }
            $recoveryAttemptedProperty = $hiveImportResult.PSObject.Properties['RecoveryAttempted']
            $recoveryReasonProperty = $hiveImportResult.PSObject.Properties['RecoveryReason']
            $recoveryAttempted = ($null -ne $recoveryAttemptedProperty -and [bool]$recoveryAttemptedProperty.Value)
            $recoveryReason = if ($null -ne $recoveryReasonProperty) { [string]$recoveryReasonProperty.Value } else { '' }
            $data = [pscustomobject]@{
                CommandStatus = if (-not $success) { 'Failed' } elseif ($completedWithWarnings) { 'Completed with warnings' } else { 'Completed' }
                VerificationStatus = $verificationResult.Status
                ExpectedNotepadSettingsState = 'Ultimate Apply writes source-defined OpenFile, GhostFile, and RewriteEnabled values through the mounted settings.dat hive'
                DetectedNotepadSettingsState = $verificationResult.DetectedState.NotepadSettings
                SettingsDatPath = $paths.SettingsDatPath
                NotepadPackageDirectoryPath = $paths.PackageDirectoryPath
                SettingsDatExists = [bool]$hiveImportResult.SettingsDatExists
                RegFilePath = $paths.RegistryFilePath
                RegFileEncoding = 'Unicode'
                RegistryImportWriteMethod = 'Set-Content source-compatible .reg payload, then reg import'
                ChangesExecuted = $true
                BackupStatus = 'Not used; Ultimate source does not create a backup.'
                BackupPath = ''
                OriginalSha256 = $null
                DetectedSha256 = $detectedFileState.Sha256
                ProcessActions = @([string]$processResult.Message)
                HiveOperations = @($hiveImportResult.HiveOperations)
                RegistryValuesChecked = @($hiveImportResult.RegistryValuesChecked)
                FileDisposition = if ($success) { 'settings.dat was targeted through the source-defined mounted hive sequence and verified before unload.' } else { 'Operation failed before a verified Notepad settings.dat state could be established.' }
                FinalStatusReason = [string]$hiveImportResult.FinalStatusReason
                Warnings = $severityWarnings.ToArray()
                InformationalNotes = $informationalNotes.ToArray()
                ExpectedNoOpOutcomes = $informationalNotes.ToArray()
                Errors = @($hiveImportResult.Errors)
                RecoveryAttempted = $recoveryAttempted
                RecoveryReason = $recoveryReason
                CompletedAt = Get-Date
            }
            return New-BoostLabNotepadResult -Success $success -Action $ActionName -Status $(if (-not $success) { 'Failed' } elseif ($completedWithWarnings) { 'Warning' } else { 'Passed' }) -Message $message -Data $data -VerificationResult $verificationResult
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
