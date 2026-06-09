Set-StrictMode -Version Latest

$verificationModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1'
if (-not (Get-Command -Name 'New-BoostLabVerificationResult' -ErrorAction SilentlyContinue)) {
    Import-Module -Name $verificationModulePath -Scope Local -Force -ErrorAction Stop
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'start-menu-layout'; Title = 'Start Menu Layout'; Stage = 'Windows'; Order = 2
    Type = 'action'; RiskLevel = 'low'
    Description = 'Apply the recommended 25H2 Start menu layout or restore the source 24H2 layout.'
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
$script:BoostLabFeatureOverrideBasePath = 'HKLM:\SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\14'
$script:BoostLabFeatureOverrideIds = @(
    '2792562829'
    '3036241548'
    '734731404'
    '762256525'
)
$script:BoostLabStartMenuRegistryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Start'

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

function New-BoostLabStartMenuLayoutResult {
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

        [bool]$RegistryProviderAvailable = $(
            $null -ne (Get-PSProvider -PSProvider Registry -ErrorAction SilentlyContinue)
        )
    )

    $registryEditorPath = if ([string]::IsNullOrWhiteSpace($SystemRoot)) {
        ''
    }
    else {
        Join-Path $SystemRoot 'regedit.exe'
    }
    $supported = (
        $OperatingSystem -eq 'Windows_NT' -and
        $RegistryProviderAvailable -and
        -not [string]::IsNullOrWhiteSpace($registryEditorPath) -and
        (Test-Path -LiteralPath $registryEditorPath -PathType Leaf)
    )

    return [pscustomobject]@{
        Supported = $supported
        ToolId    = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason    = if ($OperatingSystem -ne 'Windows_NT') {
            'Start Menu Layout requires Windows.'
        }
        elseif (-not $RegistryProviderAvailable) {
            'Start Menu Layout is unavailable because the PowerShell Registry provider was not found.'
        }
        elseif ([string]::IsNullOrWhiteSpace($registryEditorPath)) {
            'The Windows system directory is unavailable.'
        }
        elseif (-not $supported) {
            'Start Menu Layout is unavailable because regedit.exe was not found.'
        }
        else {
            'Windows Start menu registry and registry import support are available.'
        }
        Timestamp = Get-Date
    }
}

function Get-BoostLabStartMenuLayoutRegistryContent {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName
    )

    if ($ActionName -eq 'Apply') {
        return @"
Windows Registry Editor Version 5.00

; new start menu
[HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\14\2792562829]
"EnabledState"=dword:00000002

[HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\14\3036241548]
"EnabledState"=dword:00000002

[HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\14\734731404]
"EnabledState"=dword:00000002

[HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\14\762256525]
"EnabledState"=dword:00000002

; set start menu apps view to list
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Start]
"AllAppsViewMode"=dword:00000002
"@
    }

    return @"
Windows Registry Editor Version 5.00

; old start menu
[HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\14\2792562829]
"EnabledState"=-

[HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\14\3036241548]
"EnabledState"=-

[HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\14\734731404]
"EnabledState"=-

[HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\FeatureManagement\Overrides\14\762256525]
"EnabledState"=-

; set start menu apps view to category
[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Start]
"AllAppsViewMode"=dword:00000000
"@
}

function Get-BoostLabStartMenuLayoutDefinitions {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName
    )

    $definitions = [System.Collections.Generic.List[object]]::new()
    foreach ($overrideId in $script:BoostLabFeatureOverrideIds) {
        $definitions.Add(
            [pscustomobject]@{
                Path      = Join-Path $script:BoostLabFeatureOverrideBasePath $overrideId
                Name      = 'EnabledState'
                ValueType = 'DWord'
                Expected  = if ($ActionName -eq 'Apply') { '0x00000002' } else { 'Absent' }
            }
        )
    }
    $definitions.Add(
        [pscustomobject]@{
            Path      = $script:BoostLabStartMenuRegistryPath
            Name      = 'AllAppsViewMode'
            ValueType = 'DWord'
            Expected  = if ($ActionName -eq 'Apply') { '0x00000002' } else { '0x00000000' }
        }
    )

    return $definitions.ToArray()
}

function ConvertTo-BoostLabStartMenuLayoutDisplayValue {
    param(
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return 'Absent'
    }

    try {
        $signedValue = [Convert]::ToInt64($Value)
        $unsignedValue = [uint64]($signedValue -band 4294967295)
        return '0x{0:x8}' -f $unsignedValue
    }
    catch {
        return [string]$Value
    }
}

function Get-BoostLabStartMenuLayoutRegistryState {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Definition,

        [scriptblock]$RegistryReader = {
            param($Path, $Name)
            if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
                return [pscustomobject]@{
                    ReadSucceeded = $true
                    KeyExists     = $false
                    Exists        = $false
                    Value         = $null
                    DisplayValue  = 'Absent'
                    Message       = 'Registry path is absent.'
                }
            }

            $item = Get-ItemProperty -LiteralPath $Path -ErrorAction Stop
            $property = $item.PSObject.Properties[$Name]
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
                DisplayValue  = ConvertTo-BoostLabStartMenuLayoutDisplayValue -Value $property.Value
                Message       = 'Registry value detected.'
            }
        }
    )

    try {
        $results = @(& $RegistryReader $Definition.Path $Definition.Name)
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

function Get-BoostLabStartMenuLayoutFileState {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$ExpectedContent,

        [scriptblock]$FileReader = {
            param($RequestedPath)
            if (-not (Test-Path -LiteralPath $RequestedPath -PathType Leaf)) {
                return [pscustomobject]@{
                    ReadSucceeded = $true
                    Exists        = $false
                    Content       = $null
                    Message       = 'Registry import file is absent.'
                }
            }

            return [pscustomobject]@{
                ReadSucceeded = $true
                Exists        = $true
                Content       = Get-Content -LiteralPath $RequestedPath -Raw -ErrorAction Stop
                Message       = 'Registry import file detected.'
            }
        }
    )

    try {
        $results = @(& $FileReader $Path)
        if ($results.Count -eq 0 -or $null -eq $results[0]) {
            throw 'File reader returned no result.'
        }

        $state = $results[0]
        $normalizedExpected = $ExpectedContent.Replace("`r`n", "`n").TrimEnd("`r", "`n")
        $normalizedActual = if (
            $null -ne $state.PSObject.Properties['Content'] -and
            $null -ne $state.Content
        ) {
            ([string]$state.Content).Replace("`r`n", "`n").TrimEnd("`r", "`n")
        }
        else {
            ''
        }
        $state | Add-Member `
            -NotePropertyName 'ContentMatches' `
            -NotePropertyValue ($normalizedActual -eq $normalizedExpected) `
            -Force

        return $state
    }
    catch {
        return [pscustomobject]@{
            ReadSucceeded = $false
            Exists        = $false
            Content       = $null
            ContentMatches = $false
            Message       = $_.Exception.Message
        }
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $applyDefinitions = @(Get-BoostLabStartMenuLayoutDefinitions -ActionName 'Apply')
    $defaultDefinitions = @(Get-BoostLabStartMenuLayoutDefinitions -ActionName 'Default')
    $states = @(
        foreach ($definition in $applyDefinitions) {
            Get-BoostLabStartMenuLayoutRegistryState -Definition $definition
        }
    )
    $applyMatches = 0
    $defaultMatches = 0
    for ($index = 0; $index -lt $states.Count; $index++) {
        $state = $states[$index]
        if (
            [bool]$state.ReadSucceeded -and
            [string]$state.DisplayValue -eq [string]$applyDefinitions[$index].Expected
        ) {
            $applyMatches++
        }
        if (
            [bool]$state.ReadSucceeded -and
            [string]$state.DisplayValue -eq [string]$defaultDefinitions[$index].Expected
        ) {
            $defaultMatches++
        }
    }
    $status = if ($states.Count -ne 5 -or @($states | Where-Object { -not [bool]$_.ReadSucceeded }).Count -gt 0) {
        'Unavailable'
    }
    elseif ($applyMatches -eq 5) {
        '25H2 recommended'
    }
    elseif ($defaultMatches -eq 5) {
        '24H2 source layout'
    }
    else {
        'Custom'
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

function Test-BoostLabStartMenuLayoutState {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [Parameter(Mandatory)]
        [string]$RegistryFilePath,

        [Parameter(Mandatory)]
        [string]$RegistryFileContent,

        [scriptblock]$RegistryReader = {
            param($Path, $Name)
            $definition = [pscustomobject]@{ Path = $Path; Name = $Name; ValueType = 'DWord' }
            Get-BoostLabStartMenuLayoutRegistryState -Definition $definition
        },

        [scriptblock]$FileReader = {
            param($Path)
            Get-BoostLabStartMenuLayoutFileState `
                -Path $Path `
                -ExpectedContent $RegistryFileContent
        }
    )

    $checks = [System.Collections.Generic.List[object]]::new()
    foreach ($definition in @(Get-BoostLabStartMenuLayoutDefinitions -ActionName $ActionName)) {
        try {
            $stateResults = @(& $RegistryReader $definition.Path $definition.Name)
            $state = if ($stateResults.Count -gt 0) { $stateResults[0] } else { $null }
        }
        catch {
            $state = $null
        }

        $readSucceeded = (
            $null -ne $state -and
            $null -ne $state.PSObject.Properties['ReadSucceeded'] -and
            [bool]$state.ReadSucceeded
        )
        $exists = (
            $readSucceeded -and
            $null -ne $state.PSObject.Properties['Exists'] -and
            [bool]$state.Exists
        )
        $actual = if (
            $readSucceeded -and
            $null -ne $state.PSObject.Properties['DisplayValue']
        ) {
            [string]$state.DisplayValue
        }
        elseif ($readSucceeded) {
            if ($exists) { 'Present' } else { 'Absent' }
        }
        else {
            'Unknown'
        }
        $stateMessage = if (
            $null -ne $state -and
            $null -ne $state.PSObject.Properties['Message']
        ) {
            [string]$state.Message
        }
        else {
            'The registry value could not be read.'
        }
        $status = if (-not $readSucceeded) {
            'Warning'
        }
        elseif ($definition.Expected -eq 'Absent' -and -not $exists) {
            'Passed'
        }
        elseif ($exists -and $actual -eq $definition.Expected) {
            'Passed'
        }
        else {
            'Failed'
        }

        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name ('{0}\{1}' -f $definition.Path, $definition.Name) `
                -Expected ([string]$definition.Expected) `
                -Actual $actual `
                -Status $status `
                -Message $stateMessage)
        )
    }

    $fileState = Get-BoostLabStartMenuLayoutFileState `
        -Path $RegistryFilePath `
        -ExpectedContent $RegistryFileContent `
        -FileReader $FileReader
    $fileReadSucceeded = (
        $null -ne $fileState.PSObject.Properties['ReadSucceeded'] -and
        [bool]$fileState.ReadSucceeded
    )
    $fileExists = (
        $fileReadSucceeded -and
        $null -ne $fileState.PSObject.Properties['Exists'] -and
        [bool]$fileState.Exists
    )
    $contentMatches = (
        $fileReadSucceeded -and
        $null -ne $fileState.PSObject.Properties['ContentMatches'] -and
        [bool]$fileState.ContentMatches
    )
    $fileStatus = if (-not $fileReadSucceeded) {
        'Warning'
    }
    elseif ($fileExists -and $contentMatches) {
        'Passed'
    }
    else {
        'Failed'
    }
    $fileActual = if (-not $fileReadSucceeded) {
        'Unknown'
    }
    elseif (-not $fileExists) {
        'Absent'
    }
    elseif ($contentMatches) {
        'Present with approved content'
    }
    else {
        'Present with unexpected content'
    }
    $checks.Add(
        (New-BoostLabVerificationCheck `
            -Name $RegistryFilePath `
            -Expected 'Present with approved content' `
            -Actual $fileActual `
            -Status $fileStatus `
            -Message ([string]$fileState.Message))
    )

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
        '25H2 recommended layout'
    }
    else {
        '24H2 source layout (approved Default)'
    }
    $detectedState = if ($overallStatus -eq 'Passed') {
        $expectedState
    }
    elseif ($overallStatus -eq 'Warning') {
        'Partially detected'
    }
    else {
        'Unexpected Start Menu Layout state'
    }
    $message = switch ($overallStatus) {
        'Passed' { 'The expected Start Menu Layout registry and file state was detected.' }
        'Warning' { 'The command completed, but one or more Start Menu Layout states could not be detected.' }
        default { 'The detected Start Menu Layout state does not match the expected result.' }
    }

    return New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action $ActionName `
        -Status $overallStatus `
        -ExpectedState ([pscustomobject]@{ StartMenuLayout = $expectedState }) `
        -DetectedState ([pscustomobject]@{ StartMenuLayout = $detectedState }) `
        -Checks $checks.ToArray() `
        -Message $message
}

function Invoke-BoostLabStartMenuLayoutAction {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [scriptblock]$AdministratorChecker = {
            Test-BoostLabAdministrator
        },

        [scriptblock]$FileWriter = {
            param($Path, $Content)
            Set-Content -Path $Path -Value $Content -Force -ErrorAction Stop
        },

        [scriptblock]$RegistryImporter = {
            param($Path)
            $process = Start-Process `
                -Wait `
                "regedit.exe" `
                -ArgumentList "/S `"$Path`"" `
                -WindowStyle Hidden `
                -PassThru `
                -ErrorAction Stop
            if ($null -ne $process -and $process.ExitCode -ne 0) {
                throw "regedit.exe returned exit code $($process.ExitCode)."
            }
        },

        [scriptblock]$RegistryReader = {
            param($Path, $Name)
            $definition = [pscustomobject]@{ Path = $Path; Name = $Name; ValueType = 'DWord' }
            Get-BoostLabStartMenuLayoutRegistryState -Definition $definition
        },

        [scriptblock]$FileReader = {
            param($Path)
            if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
                return [pscustomobject]@{
                    ReadSucceeded = $true
                    Exists        = $false
                    Content       = $null
                    Message       = 'Registry import file is absent.'
                }
            }

            return [pscustomobject]@{
                ReadSucceeded = $true
                Exists        = $true
                Content       = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
                Message       = 'Registry import file detected.'
            }
        }
    )

    if (-not [bool](& $AdministratorChecker)) {
        return New-BoostLabStartMenuLayoutResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Administrator rights are required to import the approved Start Menu Layout registry values.'
    }
    if ([string]::IsNullOrWhiteSpace($env:SystemRoot)) {
        return New-BoostLabStartMenuLayoutResult `
            -Success $false `
            -Action $ActionName `
            -Message 'The Windows system directory is unavailable.'
    }

    $registryFileName = if ($ActionName -eq 'Apply') {
        'newstartmenu.reg'
    }
    else {
        'oldstartmenu.reg'
    }
    $registryFilePath = Join-Path (Join-Path $env:SystemRoot 'Temp') $registryFileName
    $registryContent = Get-BoostLabStartMenuLayoutRegistryContent -ActionName $ActionName
    $registryFileStatus = 'Pending'
    $registryImportStatus = 'Pending'
    $errors = [System.Collections.Generic.List[string]]::new()

    try {
        & $FileWriter $registryFilePath $registryContent | Out-Null
        $registryFileStatus = 'Written'
    }
    catch {
        $registryFileStatus = 'Failed'
        $errors.Add("Registry file creation failed: $($_.Exception.Message)")
    }

    if ($errors.Count -eq 0) {
        try {
            & $RegistryImporter $registryFilePath | Out-Null
            $registryImportStatus = 'Completed'
        }
        catch {
            $registryImportStatus = 'Failed'
            $errors.Add("Registry import failed: $($_.Exception.Message)")
        }
    }
    else {
        $registryImportStatus = 'Not attempted'
    }
    $commandStatus = if ($errors.Count -eq 0) { 'Completed' } else { 'Failed' }

    $verificationResult = Test-BoostLabStartMenuLayoutState `
        -ActionName $ActionName `
        -RegistryFilePath $registryFilePath `
        -RegistryFileContent $registryContent `
        -RegistryReader $RegistryReader `
        -FileReader $FileReader
    $expectedState = [string]$verificationResult.ExpectedState.StartMenuLayout
    $detectedState = [string]$verificationResult.DetectedState.StartMenuLayout
    $completedAt = Get-Date
    $data = [pscustomobject]@{
        CommandStatus                = $commandStatus
        ExpectedStartMenuLayoutState = $expectedState
        DetectedStartMenuLayoutState = $detectedState
        RegistryValuesChecked        = @(
            $verificationResult.Checks |
                Where-Object { $_.Name -like 'HK*' } |
                ForEach-Object { [string]$_.Name }
        )
        FilePathsChecked             = @($registryFilePath)
        RegistryFilePath             = $registryFilePath
        RegistryFileStatus           = $registryFileStatus
        RegistryImportStatus         = $registryImportStatus
        UiRefreshStatus              = 'Not performed by the Ultimate source'
        CompletedAt                  = $completedAt
    }

    if ($errors.Count -gt 0) {
        return New-BoostLabStartMenuLayoutResult `
            -Success $false `
            -Action $ActionName `
            -Message ("Start Menu Layout action failed: {0}" -f ($errors -join '; ')) `
            -Data $data `
            -VerificationResult $verificationResult
    }

    $message = if ($verificationResult.Status -eq 'Warning') {
        'Start Menu Layout command completed, but verification was incomplete.'
    }
    elseif ($verificationResult.Status -eq 'Failed') {
        'Start Menu Layout command completed, but verification detected an unexpected state.'
    }
    elseif ($ActionName -eq 'Apply') {
        'Start Menu 25H2 layout applied.'
    }
    else {
        'Start Menu 24H2 layout restored as default.'
    }

    return New-BoostLabStartMenuLayoutResult `
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
        return New-BoostLabStartMenuLayoutResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Unsupported action. Only Apply and Default are allowed.'
    }
    if (-not $Confirmed) {
        return New-BoostLabStartMenuLayoutResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Cancelled by user' `
            -Cancelled $true
    }

    return Invoke-BoostLabStartMenuLayoutAction -ActionName $ActionName
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
