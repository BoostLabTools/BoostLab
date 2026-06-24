Set-StrictMode -Version Latest

$verificationModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1'
if (-not (Get-Command -Name 'New-BoostLabVerificationResult' -ErrorAction SilentlyContinue)) {
    Import-Module -Name $verificationModulePath -Scope Local -Force -ErrorAction Stop
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'theme-black'; Title = 'Theme Black'; Stage = 'Windows'; Order = 4
    Type = 'action'; RiskLevel = 'low'
    Description = 'Apply or reset the approved dark Windows theme preference.'
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
$script:BoostLabThemePaths = [ordered]@{
    PersonalizeCurrentUser = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'
    PersonalizeLocalMachine = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'
    ExplorerAccent = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent'
    DesktopWindowManager = 'HKCU:\Software\Microsoft\Windows\DWM'
    ControlPanelColors = 'HKCU:\Control Panel\Colors'
}

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

function New-BoostLabThemeBlackResult {
    param(
        [Parameter(Mandatory)]
        [bool]$Success,

        [AllowNull()]
        [string]$Status = $null,

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
        Status             = if (-not [string]::IsNullOrWhiteSpace($Status)) {
            $Status
        }
        elseif ($Cancelled) {
            'Cancelled'
        }
        elseif ($Success) {
            'Success'
        }
        else {
            'Error'
        }
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
            'Theme Black requires Windows.'
        }
        elseif (-not $RegistryProviderAvailable) {
            'Theme Black is unavailable because the PowerShell Registry provider was not found.'
        }
        elseif ([string]::IsNullOrWhiteSpace($registryEditorPath)) {
            'The Windows system directory is unavailable.'
        }
        elseif (-not $supported) {
            'Theme Black is unavailable because regedit.exe was not found.'
        }
        else {
            'Windows theme registry and registry import support are available.'
        }
        Timestamp = Get-Date
    }
}

function Get-BoostLabThemeBlackRegistryContent {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName
    )

    if ($ActionName -eq 'Apply') {
        return @"
Windows Registry Editor Version 5.00

; dark theme & disable transparency
[HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize]
"AppsUseLightTheme"=dword:00000000
"ColorPrevalence"=dword:00000001
"EnableTransparency"=dword:00000000
"SystemUsesLightTheme"=dword:00000000

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize]
"AppsUseLightTheme"=dword:00000000

[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent]
"AccentPalette"=hex:64,64,64,00,6b,6b,6b,00,00,00,00,00,00,00,00,00,00,00,00,\
  00,00,00,00,00,00,00,00,00,00,00,00,00
"StartColorMenu"=dword:00000000
"AccentColorMenu"=dword:00000000

[HKEY_CURRENT_USER\Software\Microsoft\Windows\DWM]
"EnableWindowColorization"=dword:00000001
"AccentColor"=dword:ff191919
"ColorizationColor"=dword:c4191919
"ColorizationAfterglow"=dword:c4191919

[HKEY_CURRENT_USER\Control Panel\Colors]
"Background"="0 0 0"
"@
    }

    return @"
Windows Registry Editor Version 5.00

; light theme & enable transparency
[HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize]
"AppsUseLightTheme"=dword:00000001
"ColorPrevalence"=dword:00000000
"EnableTransparency"=dword:00000001
"SystemUsesLightTheme"=dword:00000001

[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize]

[HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Accent]
"AccentPalette"=hex:99,eb,ff,00,4c,c2,ff,00,00,91,f8,00,00,78,d4,00,00,67,c0,\
  00,00,3e,92,00,00,1a,68,00,f7,63,0c,00
"StartColorMenu"=dword:ffc06700
"AccentColorMenu"=dword:ffd47800

[HKEY_CURRENT_USER\Software\Microsoft\Windows\DWM]
"EnableWindowColorization"=dword:00000000
"AccentColor"=dword:ffd47800
"ColorizationColor"=dword:c40078d4
"ColorizationAfterglow"=dword:c40078d4

[HKEY_CURRENT_USER\Control Panel\Colors]
"Background"="0 0 0"
"@
}

function Get-BoostLabThemeBlackDefinitions {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName
    )

    $personalizeCurrentUser = [string]$script:BoostLabThemePaths['PersonalizeCurrentUser']
    $personalizeLocalMachine = [string]$script:BoostLabThemePaths['PersonalizeLocalMachine']
    $explorerAccent = [string]$script:BoostLabThemePaths['ExplorerAccent']
    $desktopWindowManager = [string]$script:BoostLabThemePaths['DesktopWindowManager']
    $controlPanelColors = [string]$script:BoostLabThemePaths['ControlPanelColors']

    if ($ActionName -eq 'Apply') {
        return @(
            [pscustomobject]@{ Path = $personalizeCurrentUser; Name = 'AppsUseLightTheme'; ValueType = 'DWord'; Expected = '0x00000000' }
            [pscustomobject]@{ Path = $personalizeCurrentUser; Name = 'ColorPrevalence'; ValueType = 'DWord'; Expected = '0x00000001' }
            [pscustomobject]@{ Path = $personalizeCurrentUser; Name = 'EnableTransparency'; ValueType = 'DWord'; Expected = '0x00000000' }
            [pscustomobject]@{ Path = $personalizeCurrentUser; Name = 'SystemUsesLightTheme'; ValueType = 'DWord'; Expected = '0x00000000' }
            [pscustomobject]@{ Path = $personalizeLocalMachine; Name = 'AppsUseLightTheme'; ValueType = 'DWord'; Expected = '0x00000000' }
            [pscustomobject]@{ Path = $explorerAccent; Name = 'AccentPalette'; ValueType = 'Binary'; Expected = '64,64,64,00,6b,6b,6b,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00' }
            [pscustomobject]@{ Path = $explorerAccent; Name = 'StartColorMenu'; ValueType = 'DWord'; Expected = '0x00000000' }
            [pscustomobject]@{ Path = $explorerAccent; Name = 'AccentColorMenu'; ValueType = 'DWord'; Expected = '0x00000000' }
            [pscustomobject]@{ Path = $desktopWindowManager; Name = 'EnableWindowColorization'; ValueType = 'DWord'; Expected = '0x00000001' }
            [pscustomobject]@{ Path = $desktopWindowManager; Name = 'AccentColor'; ValueType = 'DWord'; Expected = '0xff191919' }
            [pscustomobject]@{ Path = $desktopWindowManager; Name = 'ColorizationColor'; ValueType = 'DWord'; Expected = '0xc4191919' }
            [pscustomobject]@{ Path = $desktopWindowManager; Name = 'ColorizationAfterglow'; ValueType = 'DWord'; Expected = '0xc4191919' }
            [pscustomobject]@{ Path = $controlPanelColors; Name = 'Background'; ValueType = 'String'; Expected = '0 0 0' }
        )
    }

    return @(
        [pscustomobject]@{ Path = $personalizeCurrentUser; Name = 'AppsUseLightTheme'; ValueType = 'DWord'; Expected = '0x00000001' }
        [pscustomobject]@{ Path = $personalizeCurrentUser; Name = 'ColorPrevalence'; ValueType = 'DWord'; Expected = '0x00000000' }
        [pscustomobject]@{ Path = $personalizeCurrentUser; Name = 'EnableTransparency'; ValueType = 'DWord'; Expected = '0x00000001' }
        [pscustomobject]@{ Path = $personalizeCurrentUser; Name = 'SystemUsesLightTheme'; ValueType = 'DWord'; Expected = '0x00000001' }
        [pscustomobject]@{ Path = $personalizeLocalMachine; Name = '(key)'; ValueType = 'KeyAbsent'; Expected = 'Absent' }
        [pscustomobject]@{ Path = $explorerAccent; Name = 'AccentPalette'; ValueType = 'Binary'; Expected = '99,eb,ff,00,4c,c2,ff,00,00,91,f8,00,00,78,d4,00,00,67,c0,00,00,3e,92,00,00,1a,68,00,f7,63,0c,00' }
        [pscustomobject]@{ Path = $explorerAccent; Name = 'StartColorMenu'; ValueType = 'DWord'; Expected = '0xffc06700' }
        [pscustomobject]@{ Path = $explorerAccent; Name = 'AccentColorMenu'; ValueType = 'DWord'; Expected = '0xffd47800' }
        [pscustomobject]@{ Path = $desktopWindowManager; Name = 'EnableWindowColorization'; ValueType = 'DWord'; Expected = '0x00000000' }
        [pscustomobject]@{ Path = $desktopWindowManager; Name = 'AccentColor'; ValueType = 'DWord'; Expected = '0xffd47800' }
        [pscustomobject]@{ Path = $desktopWindowManager; Name = 'ColorizationColor'; ValueType = 'DWord'; Expected = '0xc40078d4' }
        [pscustomobject]@{ Path = $desktopWindowManager; Name = 'ColorizationAfterglow'; ValueType = 'DWord'; Expected = '0xc40078d4' }
        [pscustomobject]@{ Path = $controlPanelColors; Name = 'Background'; ValueType = 'String'; Expected = '0 0 0' }
    )
}

function ConvertTo-BoostLabThemeBlackDisplayValue {
    param(
        [AllowNull()]
        [object]$Value,

        [Parameter(Mandatory)]
        [ValidateSet('DWord', 'Binary', 'String')]
        [string]$ValueType
    )

    if ($null -eq $Value) {
        return 'Absent'
    }

    if ($ValueType -eq 'Binary') {
        try {
            return (@($Value) | ForEach-Object { ([byte]$_).ToString('x2') }) -join ','
        }
        catch {
            return [string]$Value
        }
    }
    if ($ValueType -eq 'DWord') {
        try {
            $signedValue = [Convert]::ToInt64($Value)
            $unsignedValue = [uint64]($signedValue -band 4294967295)
            return '0x{0:x8}' -f $unsignedValue
        }
        catch {
            return [string]$Value
        }
    }

    return [string]$Value
}

function Test-BoostLabThemeBlackDwmNormalizedEquivalent {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [Parameter(Mandatory)]
        [pscustomobject]$Definition,

        [Parameter(Mandatory)]
        [string]$Actual
    )

    if ($ActionName -ne 'Apply') {
        return $false
    }
    if ([string]$Definition.Path -ne [string]$script:BoostLabThemePaths['DesktopWindowManager']) {
        return $false
    }

    $expected = ([string]$Definition.Expected).ToLowerInvariant()
    $actualValue = ([string]$Actual).ToLowerInvariant()
    $allowedPairs = @{
        'AccentColor|0xff191919' = '0x00000000'
        'ColorizationColor|0xc4191919' = '0xc4000000'
        'ColorizationAfterglow|0xc4191919' = '0xc4000000'
    }
    $key = '{0}|{1}' -f [string]$Definition.Name, $expected

    return ($allowedPairs.ContainsKey($key) -and [string]$allowedPairs[$key] -eq $actualValue)
}

function ConvertFrom-BoostLabThemeBlackDWordText {
    param(
        [Parameter(Mandatory)]
        [string]$Value
    )

    $text = $Value.Trim().ToLowerInvariant()
    if ($text.StartsWith('0x')) {
        $text = $text.Substring(2)
    }
    $unsignedValue = [Convert]::ToUInt32($text, 16)
    return [BitConverter]::ToInt32([BitConverter]::GetBytes($unsignedValue), 0)
}

function Get-BoostLabThemeBlackDwmApplyDefinitions {
    @(
        Get-BoostLabThemeBlackDefinitions -ActionName 'Apply' |
            Where-Object {
                [string]$_.Path -eq [string]$script:BoostLabThemePaths['DesktopWindowManager'] -and
                [string]$_.Name -in @('AccentColor', 'ColorizationColor', 'ColorizationAfterglow')
            }
    )
}

function Get-BoostLabThemeBlackCheckByDefinition {
    param(
        [Parameter(Mandatory)]
        [object]$VerificationResult,

        [Parameter(Mandatory)]
        [pscustomobject]$Definition
    )

    $checkName = '{0}\{1}' -f [string]$Definition.Path, [string]$Definition.Name
    @($VerificationResult.Checks | Where-Object { [string]$_.Name -eq $checkName }) | Select-Object -First 1
}

function Get-BoostLabThemeBlackDwmNormalizationDetails {
    param(
        [Parameter(Mandatory)]
        [object]$VerificationResult
    )

    foreach ($definition in @(Get-BoostLabThemeBlackDwmApplyDefinitions)) {
        $check = Get-BoostLabThemeBlackCheckByDefinition -VerificationResult $VerificationResult -Definition $definition
        if ($null -eq $check) {
            continue
        }

        $normalized = (
            $null -ne $check.PSObject.Properties['NormalizedEquivalentApplied'] -and
            [bool]$check.NormalizedEquivalentApplied
        )
        $status = [string]$check.Status
        $decision = if ($normalized) {
            'AcceptedBlackNormalization'
        }
        elseif ($status -eq 'Passed') {
            'ExactSourceValue'
        }
        elseif ($status -eq 'Failed') {
            'RejectedNonBlackOrMismatched'
        }
        else {
            'UnreadableOrWarning'
        }

        [pscustomobject]@{
            Path = [string]$definition.Path
            Name = [string]$definition.Name
            Expected = [string]$definition.Expected
            Actual = [string]$check.Actual
            Status = $status
            NormalizedEquivalentApplied = $normalized
            NormalizationDecision = $decision
            Reason = if ($normalized -and $null -ne $check.PSObject.Properties['NormalizationReason']) { [string]$check.NormalizationReason } else { [string]$check.Message }
        }
    }
}

function Invoke-BoostLabThemeBlackDwmReassertion {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$RegistryValueWriter
    )

    foreach ($definition in @(Get-BoostLabThemeBlackDwmApplyDefinitions)) {
        try {
            $value = ConvertFrom-BoostLabThemeBlackDWordText -Value ([string]$definition.Expected)
            & $RegistryValueWriter ([string]$definition.Path) ([string]$definition.Name) ([string]$definition.ValueType) $value ([string]$definition.Expected) | Out-Null
            [pscustomobject]@{
                Path = [string]$definition.Path
                Name = [string]$definition.Name
                Expected = [string]$definition.Expected
                Status = 'Reasserted'
                Message = 'Source-defined Theme Black DWM value was reasserted after non-black verification.'
            }
        }
        catch {
            [pscustomobject]@{
                Path = [string]$definition.Path
                Name = [string]$definition.Name
                Expected = [string]$definition.Expected
                Status = 'Failed'
                Message = $_.Exception.Message
            }
        }
    }
}

function Get-BoostLabThemeBlackRegistryState {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Definition,

        [scriptblock]$RegistryReader = {
            param($Path, $Name, $ValueType)
            if ($ValueType -eq 'KeyAbsent') {
                $keyExists = Test-Path -LiteralPath $Path -PathType Container
                return [pscustomobject]@{
                    ReadSucceeded = $true
                    KeyExists     = $keyExists
                    Exists        = $keyExists
                    Value         = $null
                    DisplayValue  = if ($keyExists) { 'Present' } else { 'Absent' }
                    Message       = if ($keyExists) { 'Registry key detected.' } else { 'Registry key is absent.' }
                }
            }

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
                DisplayValue  = ConvertTo-BoostLabThemeBlackDisplayValue `
                    -Value $property.Value `
                    -ValueType $ValueType
                Message       = 'Registry value detected.'
            }
        }
    )

    try {
        $results = @(
            & $RegistryReader $Definition.Path $Definition.Name $Definition.ValueType
        )
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

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $definitions = @(
        Get-BoostLabThemeBlackDefinitions -ActionName 'Apply' |
            Where-Object {
                $_.Path -eq $script:BoostLabThemePaths['PersonalizeCurrentUser'] -and
                $_.Name -in @('AppsUseLightTheme', 'SystemUsesLightTheme')
            }
    )
    $states = @(
        foreach ($definition in $definitions) {
            Get-BoostLabThemeBlackRegistryState -Definition $definition
        }
    )
    $availableStates = @($states | Where-Object { [bool]$_.ReadSucceeded -and [bool]$_.Exists })
    $detectedValues = @($availableStates | ForEach-Object { [string]$_.DisplayValue })
    $status = if ($states.Count -ne 2 -or $availableStates.Count -ne 2) {
        'Unavailable'
    }
    elseif (@($detectedValues | Where-Object { $_ -ne '0x00000000' }).Count -eq 0) {
        'Black'
    }
    elseif (@($detectedValues | Where-Object { $_ -ne '0x00000001' }).Count -eq 0) {
        'Default'
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

function Test-BoostLabThemeBlackState {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [scriptblock]$RegistryReader = {
            param($Path, $Name, $ValueType)
            $definition = [pscustomobject]@{
                Path      = $Path
                Name      = $Name
                ValueType = $ValueType
            }
            Get-BoostLabThemeBlackRegistryState -Definition $definition
        }
    )

    $checks = [System.Collections.Generic.List[object]]::new()
    foreach ($definition in @(Get-BoostLabThemeBlackDefinitions -ActionName $ActionName)) {
        try {
            $stateResults = @(
                & $RegistryReader $definition.Path $definition.Name $definition.ValueType
            )
            $state = if ($stateResults.Count -gt 0) {
                $stateResults[0]
            }
            else {
                $null
            }
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
            'The registry state could not be read.'
        }
        $normalizedEquivalentApplied = (
            $readSucceeded -and
            $exists -and
            (Test-BoostLabThemeBlackDwmNormalizedEquivalent `
                -ActionName $ActionName `
                -Definition $definition `
                -Actual $actual)
        )
        $status = if (-not $readSucceeded) {
            'Warning'
        }
        elseif ($definition.ValueType -eq 'KeyAbsent' -and -not $exists) {
            'Passed'
        }
        elseif ($definition.ValueType -ne 'KeyAbsent' -and $exists -and $actual -eq $definition.Expected) {
            'Passed'
        }
        elseif ($normalizedEquivalentApplied) {
            'Passed'
        }
        else {
            'Failed'
        }
        if ($normalizedEquivalentApplied) {
            $stateMessage = '{0} Windows normalized the source-defined near-black DWM value to an equivalent black value; accepted for Theme Black verification.' -f $stateMessage
        }
        $checkName = if ($definition.ValueType -eq 'KeyAbsent') {
            [string]$definition.Path
        }
        else {
            '{0}\{1}' -f $definition.Path, $definition.Name
        }

        $check = New-BoostLabVerificationCheck `
            -Name $checkName `
            -Expected ([string]$definition.Expected) `
            -Actual $actual `
            -Status $status `
            -Message $stateMessage
        $check | Add-Member -NotePropertyName 'NormalizedEquivalentApplied' -NotePropertyValue $normalizedEquivalentApplied -Force
        if ($normalizedEquivalentApplied) {
            $check | Add-Member -NotePropertyName 'NormalizationReason' -NotePropertyValue 'Windows DWM normalized source-defined near-black Theme Black value to equivalent black.' -Force
        }
        $checks.Add($check)
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
    $expectedThemeState = if ($ActionName -eq 'Apply') {
        'Black theme'
    }
    else {
        'Default theme'
    }
    $detectedThemeState = if ($overallStatus -eq 'Passed') {
        $expectedThemeState
    }
    elseif ($overallStatus -eq 'Warning') {
        'Partially detected'
    }
    else {
        'Unexpected theme registry state'
    }
    $message = switch ($overallStatus) {
        'Passed' { 'The expected Theme Black registry state was detected.' }
        'Warning' { 'The command completed, but one or more theme registry values could not be detected.' }
        default { 'The detected theme registry state does not match the expected result.' }
    }

    return New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action $ActionName `
        -Status $overallStatus `
        -ExpectedState ([pscustomobject]@{ Theme = $expectedThemeState }) `
        -DetectedState ([pscustomobject]@{ Theme = $detectedThemeState }) `
        -Checks $checks.ToArray() `
        -Message $message
}

function Invoke-BoostLabThemeBlackAction {
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
            param($Path, $Name, $ValueType)
            $definition = [pscustomobject]@{
                Path      = $Path
                Name      = $Name
                ValueType = $ValueType
            }
            Get-BoostLabThemeBlackRegistryState -Definition $definition
        },

        [scriptblock]$RegistryValueWriter = {
            param($Path, $Name, $ValueType, $Value, $ExpectedDisplay)
            if ($ValueType -ne 'DWord') {
                throw "Theme Black DWM reassertion supports only DWord values; got $ValueType."
            }
            if ($Path -notlike 'HKCU:\*') {
                throw "Theme Black DWM reassertion is scoped to HKCU only; got $Path."
            }

            $subKeyPath = $Path -replace '^HKCU:\\', ''
            $key = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($subKeyPath)
            if ($null -eq $key) {
                throw "Unable to open registry key for DWM reassertion: $Path"
            }
            try {
                $key.SetValue($Name, [int]$Value, [Microsoft.Win32.RegistryValueKind]::DWord)
            }
            finally {
                $key.Close()
            }
        }
    )

    if (-not [bool](& $AdministratorChecker)) {
        return New-BoostLabThemeBlackResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Administrator rights are required to import the approved Theme Black registry values.'
    }
    if ([string]::IsNullOrWhiteSpace($env:SystemRoot)) {
        return New-BoostLabThemeBlackResult `
            -Success $false `
            -Action $ActionName `
            -Message 'The Windows system directory is unavailable.'
    }

    $registryFileName = if ($ActionName -eq 'Apply') {
        'blacktheme.reg'
    }
    else {
        'defaulttheme.reg'
    }
    $registryFilePath = Join-Path (Join-Path $env:SystemRoot 'Temp') $registryFileName
    $registryContent = Get-BoostLabThemeBlackRegistryContent -ActionName $ActionName
    $commandStatus = 'Pending'
    $registryFileStatus = 'Pending'
    $themeImportStatus = 'Pending'
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
            $themeImportStatus = 'Completed'
        }
        catch {
            $themeImportStatus = 'Failed'
            $errors.Add("Registry import failed: $($_.Exception.Message)")
        }
    }
    else {
        $themeImportStatus = 'Not attempted'
    }
    $commandStatus = if ($errors.Count -eq 0) {
        'Completed'
    }
    else {
        'Failed'
    }

    $verificationResult = Test-BoostLabThemeBlackState `
        -ActionName $ActionName `
        -RegistryReader $RegistryReader
    $initialDwmDetails = @(
        if ($ActionName -eq 'Apply') {
            Get-BoostLabThemeBlackDwmNormalizationDetails -VerificationResult $verificationResult
        }
    )
    $initialDwmRejected = @($initialDwmDetails | Where-Object { [string]$_.NormalizationDecision -eq 'RejectedNonBlackOrMismatched' })
    $dwmReassertionAttempted = $false
    $dwmReassertionResults = @()

    if ($ActionName -eq 'Apply' -and $errors.Count -eq 0 -and $themeImportStatus -eq 'Completed' -and $initialDwmRejected.Count -gt 0) {
        $dwmReassertionAttempted = $true
        $dwmReassertionResults = @(Invoke-BoostLabThemeBlackDwmReassertion -RegistryValueWriter $RegistryValueWriter)
        $failedReassertions = @($dwmReassertionResults | Where-Object { [string]$_.Status -eq 'Failed' })
        if ($failedReassertions.Count -gt 0) {
            $errors.Add("Theme Black DWM reassertion failed: $(@($failedReassertions | ForEach-Object { "$($_.Name): $($_.Message)" }) -join '; ')")
        }
        else {
            $verificationResult = Test-BoostLabThemeBlackState `
                -ActionName $ActionName `
                -RegistryReader $RegistryReader
        }
    }
    $expectedState = [string]$verificationResult.ExpectedState.Theme
    $detectedState = [string]$verificationResult.DetectedState.Theme
    $verificationStatus = [string]$verificationResult.Status
    $finalDwmDetails = @(
        if ($ActionName -eq 'Apply') {
            Get-BoostLabThemeBlackDwmNormalizationDetails -VerificationResult $verificationResult
        }
    )
    $finalDwmRejected = @($finalDwmDetails | Where-Object { [string]$_.NormalizationDecision -eq 'RejectedNonBlackOrMismatched' })
    $normalizedDwmChecks = @(
        $finalDwmDetails |
            Where-Object { [bool]$_.NormalizedEquivalentApplied } |
            ForEach-Object {
                [pscustomobject]@{
                    Name     = "$($_.Path)\$($_.Name)"
                    Expected = [string]$_.Expected
                    Actual   = [string]$_.Actual
                    Reason   = [string]$_.Reason
                }
            }
    )
    $reassertionDetails = @(
        foreach ($result in @($dwmReassertionResults)) {
            $before = @($initialDwmDetails | Where-Object { [string]$_.Name -eq [string]$result.Name }) | Select-Object -First 1
            $after = @($finalDwmDetails | Where-Object { [string]$_.Name -eq [string]$result.Name }) | Select-Object -First 1
            [pscustomobject]@{
                Path = [string]$result.Path
                Name = [string]$result.Name
                Expected = [string]$result.Expected
                ActualBeforeReassertion = if ($null -eq $before) { 'Unknown' } else { [string]$before.Actual }
                ActualAfterReassertion = if ($null -eq $after) { 'Unknown' } else { [string]$after.Actual }
                Status = [string]$result.Status
                Message = [string]$result.Message
                FinalNormalizationDecision = if ($null -eq $after) { 'Unknown' } else { [string]$after.NormalizationDecision }
            }
        }
    )
    $completedAt = Get-Date
    $finalStatusReason = if ($errors.Count -gt 0) {
        'CommandError'
    }
    elseif ($dwmReassertionAttempted -and $finalDwmRejected.Count -gt 0) {
        'DwmColorizationNonBlackAfterReassertion'
    }
    elseif ($verificationStatus -eq 'Failed') {
        'VerificationFailed'
    }
    elseif ($verificationStatus -eq 'Warning') {
        'VerificationWarning'
    }
    elseif ($normalizedDwmChecks.Count -gt 0) {
        'PassedWithDwmNormalization'
    }
    else {
        'CompletedVerified'
    }
    $data = [pscustomobject]@{
        CommandStatus         = $commandStatus
        VerificationStatus    = $verificationStatus
        ExpectedThemeState    = $expectedState
        DetectedThemeState    = $detectedState
        RegistryValuesChecked = @(
            $verificationResult.Checks | ForEach-Object { [string]$_.Name }
        )
        DwmNormalizationAccepted = $normalizedDwmChecks
        DwmNormalizationRejected = @(
            $finalDwmRejected | ForEach-Object {
                [pscustomobject]@{
                    Name = "$($_.Path)\$($_.Name)"
                    Expected = [string]$_.Expected
                    Actual = [string]$_.Actual
                    Reason = [string]$_.Reason
                }
            }
        )
        DwmReassertionAttempted = $dwmReassertionAttempted
        DwmReassertionResults = $reassertionDetails
        RegistryFilePath      = $registryFilePath
        RegistryFileStatus    = $registryFileStatus
        ThemeImportStatus     = $themeImportStatus
        UiRefreshStatus       = 'Not required by the Ultimate source'
        FinalStatusReason     = $finalStatusReason
        CompletedAt           = $completedAt
    }

    if ($errors.Count -gt 0) {
        return New-BoostLabThemeBlackResult `
            -Success $false `
            -Status 'Error' `
            -Action $ActionName `
            -Message ("Theme Black action failed: {0}" -f ($errors -join '; ')) `
            -Data $data `
            -VerificationResult $verificationResult
    }

    $message = if ($verificationResult.Status -eq 'Warning') {
        'Theme command completed, but verification was incomplete.'
    }
    elseif ($verificationResult.Status -eq 'Failed') {
        'Theme command completed, but verification detected an unexpected state.'
    }
    elseif ($ActionName -eq 'Apply') {
        'Black theme applied.'
    }
    else {
        'Theme restored to default.'
    }
    if ($normalizedDwmChecks.Count -gt 0) {
        $noun = if ($normalizedDwmChecks.Count -eq 1) { 'value was' } else { 'values were' }
        $message = "$message $($normalizedDwmChecks.Count) DWM color $noun normalized by Windows to equivalent black and accepted."
    }
    if ($finalDwmRejected.Count -gt 0) {
        $message = "$message Rejected non-black DWM value(s): $(@($finalDwmRejected | ForEach-Object { "$($_.Name)=$($_.Actual)" }) -join ', ')."
    }

    $success = $verificationStatus -ne 'Failed'
    $status = if ($verificationStatus -eq 'Failed') {
        'Error'
    }
    elseif ($verificationStatus -eq 'Warning') {
        'Warning'
    }
    else {
        'Success'
    }

    return New-BoostLabThemeBlackResult `
        -Success $success `
        -Status $status `
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
        return New-BoostLabThemeBlackResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Unsupported action. Only Apply and Default are allowed.'
    }
    if (-not $Confirmed) {
        return New-BoostLabThemeBlackResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Cancelled by user' `
            -Cancelled $true
    }

    return Invoke-BoostLabThemeBlackAction -ActionName $ActionName
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
