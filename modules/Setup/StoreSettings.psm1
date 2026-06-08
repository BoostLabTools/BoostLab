Set-StrictMode -Version Latest

$verificationModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1'
if (-not (Get-Command -Name 'New-BoostLabVerificationResult' -ErrorAction SilentlyContinue)) {
    Import-Module -Name $verificationModulePath -Scope Local -Force -ErrorAction Stop
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'store-settings'; Title = 'Store Settings'; Stage = 'Setup'; Order = 7
    Type = 'action'; RiskLevel = 'low'
    Description = 'Optimize Microsoft Store update and preference settings or restore the approved default behavior.'
    Actions = @('Apply', 'Default')
    Capabilities = [ordered]@{
        RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false
        CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false
        CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $false
        CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false
        SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Apply', 'Default')
$script:BoostLabStoreProcessNames = @('WinStore.App', 'backgroundTaskHost', 'StoreDesktopExtension')
$script:BoostLabWindowsStoreProviderPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore'
$script:BoostLabWindowsUpdateProviderPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate'
$script:BoostLabStoreSettingsUri = 'ms-windows-store:settings'
$script:BoostLabStoreAutoDownloadName = 'AutoDownload'
$script:BoostLabStoreHiveValues = @(
    [pscustomobject]@{
        Path = 'HKLM:\Settings\LocalState'
        Name = 'VideoAutoplay'
        Expected = '00,96,9d,69,8d,cd,93,dc,01'
    }
    [pscustomobject]@{
        Path = 'HKLM:\Settings\LocalState'
        Name = 'EnableAppInstallNotifications'
        Expected = '00,36,d0,88,8e,cd,93,dc,01'
    }
    [pscustomobject]@{
        Path = 'HKLM:\Settings\LocalState\PersistentSettings'
        Name = 'PersonalizationEnabled'
        Expected = '00,0d,56,a1,8a,cd,93,dc,01'
    }
)
$script:BoostLabStoreRegistryFileContent = @'
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\Settings\LocalState]
; disable video autoplay
"VideoAutoplay"=hex(5f5e10b):00,96,9d,69,8d,cd,93,dc,01
; disable notifications for app installations
"EnableAppInstallNotifications"=hex(5f5e10b):00,36,d0,88,8e,cd,93,dc,01

[HKEY_LOCAL_MACHINE\Settings\LocalState\PersistentSettings]
; disable personalized experiences
"PersonalizationEnabled"=hex(5f5e10b):00,0d,56,a1,8a,cd,93,dc,01
'@

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

function New-BoostLabStoreSettingsResult {
    param(
        [Parameter(Mandatory)]
        [bool]$Success,

        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [string]$Message,

        [bool]$Cancelled = $false,

        [AllowNull()]
        [object]$Data = $null,

        [AllowNull()]
        [object]$VerificationResult = $null
    )

    return [pscustomobject]@{
        Success            = $Success
        ToolId             = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle          = [string]$script:BoostLabToolMetadata['Title']
        Action             = $Action
        Message            = $Message
        RestartRequired    = $false
        Cancelled          = $Cancelled
        Timestamp          = Get-Date
        Data               = $Data
        VerificationResult = $VerificationResult
    }
}

function Get-BoostLabToolInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        Id                 = [string]$script:BoostLabToolMetadata['Id']
        Title              = [string]$script:BoostLabToolMetadata['Title']
        Stage              = [string]$script:BoostLabToolMetadata['Stage']
        Order              = [int]$script:BoostLabToolMetadata['Order']
        Type               = [string]$script:BoostLabToolMetadata['Type']
        RiskLevel          = [string]$script:BoostLabToolMetadata['RiskLevel']
        Description        = [string]$script:BoostLabToolMetadata['Description']
        Actions            = @($script:BoostLabToolMetadata['Actions'])
        Capabilities       = [pscustomobject]$script:BoostLabToolMetadata['Capabilities']
        ImplementedActions = @($script:BoostLabImplementedActions)
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string]$OperatingSystem = $env:OS,

        [string]$SystemRoot = $env:SystemRoot,

        [string]$LocalAppData = $env:LocalAppData
    )

    $commandProcessorPath = if ([string]::IsNullOrWhiteSpace($SystemRoot)) {
        ''
    }
    else {
        Join-Path $SystemRoot 'System32\cmd.exe'
    }
    $settingsDatPath = if ([string]::IsNullOrWhiteSpace($LocalAppData)) {
        ''
    }
    else {
        Join-Path $LocalAppData 'Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\Settings\settings.dat'
    }
    $supported = (
        $OperatingSystem -eq 'Windows_NT' -and
        -not [string]::IsNullOrWhiteSpace($commandProcessorPath) -and
        (Test-Path -LiteralPath $commandProcessorPath -PathType Leaf)
    )

    return [pscustomobject]@{
        Supported = $supported
        ToolId    = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason    = if ($OperatingSystem -ne 'Windows_NT') {
            'Store Settings requires Windows.'
        }
        elseif ([string]::IsNullOrWhiteSpace($commandProcessorPath) -or -not $supported) {
            'Store Settings is unavailable because cmd.exe was not found.'
        }
        elseif ([string]::IsNullOrWhiteSpace($settingsDatPath)) {
            'The current user Microsoft Store settings path is unavailable.'
        }
        else {
            'Microsoft Store settings and registry command support are available.'
        }
        Timestamp = Get-Date
    }
}

function ConvertTo-BoostLabStoreValueDisplay {
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return 'Absent'
    }
    if ($Value -is [byte[]]) {
        return (@($Value | ForEach-Object { $_.ToString('x2') }) -join ',')
    }

    return [string]$Value
}

function Get-BoostLabStoreRegistryValue {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name,

        [scriptblock]$RegistryReader = {
            param($RequestedPath, $RequestedName)
            if (-not (Test-Path -LiteralPath $RequestedPath -PathType Container)) {
                return [pscustomobject]@{
                    ReadSucceeded = $true
                    KeyExists     = $false
                    Exists        = $false
                    Value         = $null
                    DisplayValue  = 'Absent'
                    Message       = 'Registry path is absent.'
                }
            }

            $item = Get-ItemProperty -LiteralPath $RequestedPath -ErrorAction Stop
            $property = $item.PSObject.Properties[$RequestedName]
            if ($null -eq $property) {
                return [pscustomobject]@{
                    ReadSucceeded = $true
                    KeyExists     = $true
                    Exists        = $false
                    Value         = $null
                    DisplayValue  = 'Absent'
                    Message       = 'Registry value is absent.'
                }
            }

            return [pscustomobject]@{
                ReadSucceeded = $true
                KeyExists     = $true
                Exists        = $true
                Value         = $property.Value
                DisplayValue  = ConvertTo-BoostLabStoreValueDisplay -Value $property.Value
                Message       = 'Registry value detected.'
            }
        }
    )

    try {
        $results = @(& $RegistryReader $Path $Name)
        if ($results.Count -eq 0 -or $null -eq $results[0]) {
            throw 'Registry reader returned no result.'
        }

        return $results[0]
    }
    catch {
        return [pscustomobject]@{
            ReadSucceeded = $false
            KeyExists     = $null
            Exists        = $false
            Value         = $null
            DisplayValue  = 'Unknown'
            Message       = $_.Exception.Message
        }
    }
}

function Get-BoostLabStoreRegistryPathState {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [scriptblock]$RegistryPathReader = {
            param($RequestedPath)
            $exists = Test-Path -LiteralPath $RequestedPath -PathType Container
            return [pscustomobject]@{
                ReadSucceeded = $true
                Exists        = $exists
                DisplayValue  = if ($exists) { 'Present' } else { 'Absent' }
                Message       = if ($exists) {
                    'Registry path is present.'
                }
                else {
                    'Registry path is absent.'
                }
            }
        }
    )

    try {
        $results = @(& $RegistryPathReader $Path)
        if ($results.Count -eq 0 -or $null -eq $results[0]) {
            throw 'Registry path reader returned no result.'
        }

        return $results[0]
    }
    catch {
        return [pscustomobject]@{
            ReadSucceeded = $false
            Exists        = $false
            DisplayValue  = 'Unknown'
            Message       = $_.Exception.Message
        }
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $state = Get-BoostLabStoreRegistryValue `
        -Path $script:BoostLabWindowsUpdateProviderPath `
        -Name $script:BoostLabStoreAutoDownloadName
    $status = if (-not [bool]$state.ReadSucceeded) {
        'Unavailable'
    }
    elseif (-not [bool]$state.Exists) {
        'Default'
    }
    elseif ([string]$state.Value -eq '2') {
        'Optimized'
    }
    else {
        "AutoDownload: $($state.DisplayValue)"
    }

    return [pscustomobject]@{
        ToolId          = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
        Status          = $status
        LastAction      = $null
        LastResult      = $null
        RestartRequired = $false
        Timestamp       = Get-Date
    }
}

function New-BoostLabStoreVerificationCheck {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [string]$Expected,

        [Parameter(Mandatory)]
        [object]$State
    )

    $status = if (-not [bool]$State.ReadSucceeded) {
        'Warning'
    }
    elseif (-not [bool]$State.Exists) {
        'Failed'
    }
    elseif ([string]$State.DisplayValue -eq $Expected) {
        'Passed'
    }
    else {
        'Failed'
    }

    return New-BoostLabVerificationCheck `
        -Name $Name `
        -Expected $Expected `
        -Actual ([string]$State.DisplayValue) `
        -Status $status `
        -Message ([string]$State.Message)
}

function Test-BoostLabStoreSettingsState {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [scriptblock]$RegistryReader = {
            param($Path, $Name)
            Get-BoostLabStoreRegistryValue -Path $Path -Name $Name
        },

        [scriptblock]$RegistryPathReader = {
            param($Path)
            Get-BoostLabStoreRegistryPathState -Path $Path
        },

        [AllowNull()]
        [object[]]$CapturedStoreHiveStates = $null
    )

    $checks = [System.Collections.Generic.List[object]]::new()
    $autoDownloadResults = @(
        & $RegistryReader `
            $script:BoostLabWindowsUpdateProviderPath `
            $script:BoostLabStoreAutoDownloadName
    )
    $autoDownload = if ($autoDownloadResults.Count -gt 0) {
        $autoDownloadResults[0]
    }
    else {
        $null
    }
    if ($null -eq $autoDownload) {
        $autoDownload = [pscustomobject]@{
            ReadSucceeded = $false
            Exists        = $false
            Value         = $null
            DisplayValue  = 'Unknown'
            Message       = 'AutoDownload state was unavailable.'
        }
    }

    if ($ActionName -eq 'Apply') {
        $autoDownloadCheck = New-BoostLabStoreVerificationCheck `
            -Name 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate\AutoDownload' `
            -Expected '2' `
            -State $autoDownload
        $checks.Add($autoDownloadCheck)

        $capturedLookup = @{}
        foreach ($capturedState in @($CapturedStoreHiveStates)) {
            if ($null -ne $capturedState) {
                $capturedLookup["$($capturedState.Path)|$($capturedState.Name)"] = $capturedState
            }
        }
        foreach ($definition in $script:BoostLabStoreHiveValues) {
            $lookupKey = "$($definition.Path)|$($definition.Name)"
            $state = if ($capturedLookup.ContainsKey($lookupKey)) {
                $capturedLookup[$lookupKey]
            }
            else {
                [pscustomobject]@{
                    ReadSucceeded = $false
                    Exists        = $false
                    Value         = $null
                    DisplayValue  = 'Unknown'
                    Message       = 'The Store settings hive value was not captured before unload.'
                }
            }
            $checks.Add(
                (New-BoostLabStoreVerificationCheck `
                    -Name "$($definition.Path)\$($definition.Name)" `
                    -Expected ([string]$definition.Expected) `
                    -State $state)
            )
        }
    }
    else {
        $pathResults = @(& $RegistryPathReader $script:BoostLabWindowsStoreProviderPath)
        $windowsStorePath = if ($pathResults.Count -gt 0) {
            $pathResults[0]
        }
        else {
            $null
        }
        if ($null -eq $windowsStorePath) {
            $windowsStorePath = [pscustomobject]@{
                ReadSucceeded = $false
                Exists        = $false
                DisplayValue  = 'Unknown'
                Message       = 'WindowsStore registry path state was unavailable.'
            }
        }
        $status = if (-not [bool]$windowsStorePath.ReadSucceeded) {
            'Warning'
        }
        elseif ([bool]$windowsStorePath.Exists) {
            'Failed'
        }
        else {
            'Passed'
        }
        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore' `
                -Expected 'Absent' `
                -Actual ([string]$windowsStorePath.DisplayValue) `
                -Status $status `
                -Message ([string]$windowsStorePath.Message))
        )
    }

    $overallStatus = if (@($checks | Where-Object { $_.Status -eq 'Failed' }).Count -gt 0) {
        'Failed'
    }
    elseif (@($checks | Where-Object { $_.Status -eq 'Warning' }).Count -gt 0) {
        'Warning'
    }
    else {
        'Passed'
    }
    $expectedState = if ($ActionName -eq 'Apply') {
        'Optimized Store update and preference values'
    }
    else {
        'Default WindowsStore policy state'
    }
    $detectedState = if ($overallStatus -eq 'Passed') {
        $expectedState
    }
    elseif ($overallStatus -eq 'Warning') {
        'Partially detected'
    }
    else {
        'Unexpected Store settings state'
    }
    $message = switch ($overallStatus) {
        'Passed' { 'The expected Store Settings state was detected.' }
        'Warning' { 'Store Settings commands completed, but one or more values could not be detected.' }
        default { 'The detected Store Settings state does not match the expected result.' }
    }

    return New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action $ActionName `
        -Status $overallStatus `
        -ExpectedState ([pscustomobject]@{ StoreSettings = $expectedState }) `
        -DetectedState ([pscustomobject]@{ StoreSettings = $detectedState }) `
        -Checks $checks.ToArray() `
        -Message $message
}

function Invoke-BoostLabStoreRegistryCommand {
    param(
        [Parameter(Mandatory)]
        [string]$CommandText
    )

    if ([string]::IsNullOrWhiteSpace($env:SystemRoot)) {
        throw 'The Windows system directory is unavailable.'
    }
    $commandProcessorPath = Join-Path $env:SystemRoot 'System32\cmd.exe'
    if (-not (Test-Path -LiteralPath $commandProcessorPath -PathType Leaf)) {
        throw 'cmd.exe was not found.'
    }

    $output = & $commandProcessorPath /c $CommandText 2>&1
    if ($LASTEXITCODE -ne 0) {
        $detail = (@($output) -join ' ').Trim()
        if ([string]::IsNullOrWhiteSpace($detail)) {
            $detail = "Registry command returned exit code $LASTEXITCODE."
        }

        throw $detail
    }
}

function Stop-BoostLabStoreProcesses {
    param()

    $results = [System.Collections.Generic.List[object]]::new()
    foreach ($processName in $script:BoostLabStoreProcessNames) {
        $runningProcesses = @(Get-Process -Name $processName -ErrorAction SilentlyContinue)
        if ($runningProcesses.Count -eq 0) {
            $results.Add([pscustomobject]@{
                Name = $processName
                Status = 'Not running'
                Success = $true
                Message = "$processName was not running."
            })
            continue
        }

        try {
            Stop-Process -Name $processName -Force -ErrorAction SilentlyContinue
            $remaining = @(Get-Process -Name $processName -ErrorAction SilentlyContinue)
            $stopped = $remaining.Count -eq 0
            $results.Add([pscustomobject]@{
                Name = $processName
                Status = if ($stopped) { 'Stopped' } else { 'Failed' }
                Success = $stopped
                Message = if ($stopped) {
                    "$processName was stopped."
                }
                else {
                    "$processName remained running after the stop request."
                }
            })
        }
        catch {
            $results.Add([pscustomobject]@{
                Name = $processName
                Status = 'Failed'
                Success = $false
                Message = $_.Exception.Message
            })
        }
    }

    return $results.ToArray()
}

function Invoke-BoostLabStoreSettingsAction {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [scriptblock]$AdministratorChecker = {
            Test-BoostLabAdministrator
        },

        [scriptblock]$RegistryCommandInvoker = {
            param($CommandText)
            Invoke-BoostLabStoreRegistryCommand -CommandText $CommandText
        },

        [scriptblock]$RegistryReader = {
            param($Path, $Name)
            Get-BoostLabStoreRegistryValue -Path $Path -Name $Name
        },

        [scriptblock]$RegistryPathReader = {
            param($Path)
            Get-BoostLabStoreRegistryPathState -Path $Path
        },

        [scriptblock]$ProcessStopper = {
            Stop-BoostLabStoreProcesses
        },

        [scriptblock]$StoreLauncher = {
            param($Target)
            if ($Target -eq 'Settings') {
                Start-Process "ms-windows-store:settings" -ErrorAction Stop
            }
            else {
                Start-Process "wsreset.exe" -WindowStyle Hidden -ErrorAction Stop
            }
        },

        [scriptblock]$DelayInvoker = {
            param($Seconds)
            Start-Sleep -Seconds $Seconds
        },

        [scriptblock]$RegistryFileWriter = {
            param($Path, $Content)
            Set-Content -LiteralPath $Path -Value $Content -Force -ErrorAction Stop
        },

        [scriptblock]$PathTester = {
            param($Path)
            Test-Path -LiteralPath $Path -PathType Leaf
        },

        [string]$SystemRoot = $env:SystemRoot,

        [string]$LocalAppData = $env:LocalAppData
    )

    if (-not [bool](& $AdministratorChecker)) {
        return New-BoostLabStoreSettingsResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Administrator rights are required to change Store Settings.'
    }
    if ([string]::IsNullOrWhiteSpace($SystemRoot) -or [string]::IsNullOrWhiteSpace($LocalAppData)) {
        return New-BoostLabStoreSettingsResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Store Settings paths are unavailable for the current Windows user.'
    }

    $registryFilePath = Join-Path $SystemRoot 'Temp\windowsstore.reg'
    $settingsDatPath = Join-Path $LocalAppData 'Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\Settings\settings.dat'
    $processActions = [System.Collections.Generic.List[string]]::new()
    $storeUiActions = [System.Collections.Generic.List[string]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()
    $capturedStoreHiveStates = [System.Collections.Generic.List[object]]::new()
    $commandStatus = 'Pending'

    if ($ActionName -eq 'Apply') {
        try {
            & $StoreLauncher 'Settings' | Out-Null
            $storeUiActions.Add('Microsoft Store Settings opened before optimization.')
        }
        catch {
            $warnings.Add("Initial Microsoft Store Settings launch failed: $($_.Exception.Message)")
        }
        & $DelayInvoker 5 | Out-Null

        foreach ($processResult in @(& $ProcessStopper)) {
            if ($null -ne $processResult) {
                $processActions.Add("$($processResult.Name): $($processResult.Status)")
                if (-not [bool]$processResult.Success) {
                    $errors.Add([string]$processResult.Message)
                }
            }
        }
        & $DelayInvoker 2 | Out-Null

        try {
            & $RegistryCommandInvoker 'reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate" /v "AutoDownload" /t REG_DWORD /d "2" /f' | Out-Null
            & $RegistryFileWriter $registryFilePath $script:BoostLabStoreRegistryFileContent | Out-Null

            if (-not [bool](& $PathTester $settingsDatPath)) {
                throw "Microsoft Store settings.dat was not found: $settingsDatPath"
            }

            $hiveLoaded = $false
            try {
                & $RegistryCommandInvoker ('reg load "HKLM\Settings" "{0}"' -f $settingsDatPath) | Out-Null
                $hiveLoaded = $true
                & $RegistryCommandInvoker ('reg import "{0}"' -f $registryFilePath) | Out-Null

                foreach ($definition in $script:BoostLabStoreHiveValues) {
                    $stateResults = @(& $RegistryReader $definition.Path $definition.Name)
                    $state = if ($stateResults.Count -gt 0) {
                        $stateResults[0]
                    }
                    else {
                        $null
                    }
                    if ($null -eq $state) {
                        $state = [pscustomobject]@{
                            ReadSucceeded = $false
                            Exists = $false
                            Value = $null
                            DisplayValue = 'Unknown'
                            Message = 'Store hive reader returned no result.'
                        }
                    }
                    $state | Add-Member -NotePropertyName 'Path' -NotePropertyValue $definition.Path -Force
                    $state | Add-Member -NotePropertyName 'Name' -NotePropertyValue $definition.Name -Force
                    $capturedStoreHiveStates.Add($state)
                }
            }
            finally {
                if ($hiveLoaded) {
                    [gc]::Collect()
                    & $DelayInvoker 2 | Out-Null
                    try {
                        & $RegistryCommandInvoker 'reg unload "HKLM\Settings"' | Out-Null
                    }
                    catch {
                        $errors.Add("Store settings hive unload failed: $($_.Exception.Message)")
                    }
                }
            }
            $commandStatus = if ($errors.Count -gt 0) { 'Completed with errors' } else { 'Completed' }
        }
        catch {
            $commandStatus = 'Failed'
            $errors.Add("Store optimization command failed: $($_.Exception.Message)")
        }

        & $DelayInvoker 2 | Out-Null
        try {
            & $StoreLauncher 'Settings' | Out-Null
            $storeUiActions.Add('Microsoft Store Settings opened after optimization.')
        }
        catch {
            $errors.Add("Final Microsoft Store Settings launch failed: $($_.Exception.Message)")
        }
    }
    else {
        $initialPathState = Get-BoostLabStoreRegistryPathState `
            -Path $script:BoostLabWindowsStoreProviderPath `
            -RegistryPathReader $RegistryPathReader
        if ([bool]$initialPathState.ReadSucceeded -and -not [bool]$initialPathState.Exists) {
            $commandStatus = 'Registry already default'
        }
        else {
            try {
                & $RegistryCommandInvoker 'reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsStore" /f' | Out-Null
                $commandStatus = 'Completed'
            }
            catch {
                $commandStatus = 'Failed'
                $errors.Add("WindowsStore registry reset failed: $($_.Exception.Message)")
            }
        }

        foreach ($passName in @('Before wsreset', 'After wsreset')) {
            foreach ($processResult in @(& $ProcessStopper)) {
                if ($null -ne $processResult) {
                    $processActions.Add("$passName - $($processResult.Name): $($processResult.Status)")
                    if (-not [bool]$processResult.Success) {
                        $errors.Add([string]$processResult.Message)
                    }
                }
            }

            if ($passName -eq 'Before wsreset') {
                & $DelayInvoker 2 | Out-Null
                try {
                    & $StoreLauncher 'Reset' | Out-Null
                    $storeUiActions.Add('wsreset.exe launched.')
                }
                catch {
                    $errors.Add("Microsoft Store reset launch failed: $($_.Exception.Message)")
                }
            }
        }
        & $DelayInvoker 2 | Out-Null
        try {
            & $StoreLauncher 'Settings' | Out-Null
            $storeUiActions.Add('Microsoft Store Settings opened after reset.')
        }
        catch {
            $errors.Add("Microsoft Store Settings launch failed: $($_.Exception.Message)")
        }
    }

    $verificationResult = Test-BoostLabStoreSettingsState `
        -ActionName $ActionName `
        -RegistryReader $RegistryReader `
        -RegistryPathReader $RegistryPathReader `
        -CapturedStoreHiveStates $capturedStoreHiveStates.ToArray()
    $expectedState = [string]$verificationResult.ExpectedState.StoreSettings
    $detectedState = [string]$verificationResult.DetectedState.StoreSettings
    $registryValuesChecked = @($verificationResult.Checks | ForEach-Object { [string]$_.Name })
    $completedAt = Get-Date
    $data = [pscustomobject]@{
        CommandStatus             = $commandStatus
        ExpectedStoreSettingsState = $expectedState
        DetectedStoreSettingsState = $detectedState
        RegistryValuesChecked     = $registryValuesChecked
        ProcessActions            = $processActions.ToArray()
        StoreUiActions            = $storeUiActions.ToArray() -join [Environment]::NewLine
        Warnings                  = $warnings.ToArray()
        CompletedAt               = $completedAt
    }

    if ($errors.Count -gt 0) {
        return New-BoostLabStoreSettingsResult `
            -Success $false `
            -Action $ActionName `
            -Message ("Store Settings action completed with errors: {0}" -f ($errors -join '; ')) `
            -Data $data `
            -VerificationResult $verificationResult
    }

    $message = if ($verificationResult.Status -eq 'Warning') {
        'Store Settings command completed, but verification was incomplete.'
    }
    elseif ($verificationResult.Status -eq 'Failed') {
        'Store Settings command completed, but verification detected an unexpected state.'
    }
    elseif ($ActionName -eq 'Apply') {
        'Store settings optimized.'
    }
    else {
        'Store settings restored to default.'
    }
    if ($warnings.Count -gt 0) {
        $message = "$message Warning: $($warnings -join '; ')"
    }

    return New-BoostLabStoreSettingsResult `
        -Success $true `
        -Action $ActionName `
        -Message $message `
        -Data $data `
        -VerificationResult $verificationResult
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
        return New-BoostLabStoreSettingsResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Unsupported action. Only Apply and Default are allowed.'
    }
    if (-not $Confirmed) {
        return New-BoostLabStoreSettingsResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Cancelled by user' `
            -Cancelled $true
    }

    return Invoke-BoostLabStoreSettingsAction -ActionName $ActionName
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
