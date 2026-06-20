Set-StrictMode -Version Latest

$verificationModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1'
if (-not (Get-Command -Name 'New-BoostLabVerificationResult' -ErrorAction SilentlyContinue)) {
    Import-Module -Name $verificationModulePath -Scope Local -Force -ErrorAction Stop
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'context-menu'; Title = 'Context Menu'; Stage = 'Windows'; Order = 3
    Type = 'action'; RiskLevel = 'medium'
    Description = 'Apply the approved clean context menu or restore its source-defined handlers safely.'
    Actions = @('Apply', 'Default')
    Capabilities = [ordered]@{
        RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false
        CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $false
        CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $true
        CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false
        SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Apply', 'Default')
$script:BoostLabBlockedKey = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked'
$script:BoostLabBlockedRegistryPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked'
$script:BoostLabOwnedBlockedGuids = @(
    '{9F156763-7844-4DC4-B2B1-901F640F5155}'
    '{09A47860-11B0-4DA5-AFA5-26D86198A780}'
    '{f81e9010-6ea4-11ce-a7ff-00aa003ca9f6}'
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

function New-BoostLabContextMenuResult {
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

    $commandProcessorPath = if ([string]::IsNullOrWhiteSpace($SystemRoot)) {
        ''
    }
    else {
        Join-Path $SystemRoot 'System32\cmd.exe'
    }
    $registryEditorPath = if ([string]::IsNullOrWhiteSpace($SystemRoot)) {
        ''
    }
    else {
        Join-Path $SystemRoot 'regedit.exe'
    }
    $supported = (
        $OperatingSystem -eq 'Windows_NT' -and
        $RegistryProviderAvailable -and
        (Test-Path -LiteralPath $commandProcessorPath -PathType Leaf) -and
        (Test-Path -LiteralPath $registryEditorPath -PathType Leaf)
    )

    return [pscustomobject]@{
        Supported = $supported
        ToolId    = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason    = if ($OperatingSystem -ne 'Windows_NT') {
            'Context Menu requires Windows.'
        }
        elseif (-not $RegistryProviderAvailable) {
            'Context Menu is unavailable because the PowerShell Registry provider was not found.'
        }
        elseif ([string]::IsNullOrWhiteSpace($SystemRoot)) {
            'The Windows system directory is unavailable.'
        }
        elseif (-not $supported) {
            'Context Menu requires the built-in cmd.exe and regedit.exe tools.'
        }
        else {
            'Windows registry and registry import support are available.'
        }
        Timestamp = Get-Date
    }
}

function Get-BoostLabContextMenuDefaultRegistryContent {
    return @"
Windows Registry Editor Version 5.00

; pin to quick access
[HKEY_CLASSES_ROOT\Folder\shell\pintohome]
"AppliesTo"="System.ParsingName:<>\"::{f874310e-b6b7-47dc-bc84-b9e6b38f5903}\" AND System.ParsingName:<>\"::{679f85cb-0220-4080-b29b-5540cc05aab6}\" AND System.IsFolder:=System.StructuredQueryType.Boolean#True"
"CommandStateHandler"="{b455f46e-e4af-4035-b0a4-cf18d2f6f28e}"
"CommandStateSync"=""
"MUIVerb"="@shell32.dll,-51601"
"SkipCloudDownload"=dword:00000000

[HKEY_CLASSES_ROOT\Folder\shell\pintohome\command]
"DelegateExecute"="{b455f46e-e4af-4035-b0a4-cf18d2f6f28e}"

; add to favorites
[HKEY_CLASSES_ROOT\*\shell\pintohomefile]
"CommandStateHandler"="{b455f46e-e4af-4035-b0a4-cf18d2f6f28e}"
"CommandStateSync"=""
"MUIVerb"="@shell32.dll,-51608"
"NeverDefault"=""
"SkipCloudDownload"=dword:00000000

[HKEY_CLASSES_ROOT\*\shell\pintohomefile\command]
"DelegateExecute"="{b455f46e-e4af-4035-b0a4-cf18d2f6f28e}"
"@
}

function New-BoostLabContextMenuOperation {
    param(
        [Parameter(Mandatory)]
        [string]$Id,

        [Parameter(Mandatory)]
        [ValidateSet('Add', 'DeleteKey', 'DeleteValue', 'ImportDefaultFile')]
        [string]$Kind,

        [string]$Key = '',

        [string]$Name = '',

        [string]$ValueType = '',

        [AllowEmptyString()]
        [string]$Data = ''
    )

    return [pscustomobject]@{
        Id        = $Id
        Kind      = $Kind
        Key       = $Key
        Name      = $Name
        ValueType = $ValueType
        Data      = $Data
    }
}

function Get-BoostLabContextMenuOperations {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName
    )

    if ($ActionName -eq 'Apply') {
        return @(
            (New-BoostLabContextMenuOperation -Id 'ClassicContextMenu' -Kind 'Add' -Key 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' -ValueType 'REG_SZ')
            (New-BoostLabContextMenuOperation -Id 'NoCustomizeThisFolder' -Kind 'Add' -Key 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'NoCustomizeThisFolder' -ValueType 'REG_DWORD' -Data '1')
            (New-BoostLabContextMenuOperation -Id 'PinToHome' -Kind 'DeleteKey' -Key 'HKCR\Folder\shell\pintohome')
            (New-BoostLabContextMenuOperation -Id 'AddToFavorites' -Kind 'DeleteKey' -Key 'HKCR\*\shell\pintohomefile')
            (New-BoostLabContextMenuOperation -Id 'Compatibility' -Kind 'DeleteKey' -Key 'HKCR\exefile\shellex\ContextMenuHandlers\Compatibility')
            (New-BoostLabContextMenuOperation -Id 'OpenInTerminal' -Kind 'Add' -Key $script:BoostLabBlockedKey -Name $script:BoostLabOwnedBlockedGuids[0] -ValueType 'REG_SZ')
            (New-BoostLabContextMenuOperation -Id 'ScanWithDefender' -Kind 'Add' -Key $script:BoostLabBlockedKey -Name $script:BoostLabOwnedBlockedGuids[1] -ValueType 'REG_SZ')
            (New-BoostLabContextMenuOperation -Id 'GiveAccessTo' -Kind 'Add' -Key $script:BoostLabBlockedKey -Name $script:BoostLabOwnedBlockedGuids[2] -ValueType 'REG_SZ')
            (New-BoostLabContextMenuOperation -Id 'LibraryLocation' -Kind 'DeleteKey' -Key 'HKCR\Folder\ShellEx\ContextMenuHandlers\Library Location')
            (New-BoostLabContextMenuOperation -Id 'ModernSharing' -Kind 'DeleteKey' -Key 'HKCR\AllFilesystemObjects\shellex\ContextMenuHandlers\ModernSharing')
            (New-BoostLabContextMenuOperation -Id 'PreviousVersions' -Kind 'Add' -Key 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'NoPreviousVersionsPage' -ValueType 'REG_DWORD' -Data '1')
            (New-BoostLabContextMenuOperation -Id 'SendToAllFilesystemObjects' -Kind 'DeleteKey' -Key 'HKCR\AllFilesystemObjects\shellex\ContextMenuHandlers\SendTo')
            (New-BoostLabContextMenuOperation -Id 'SendToUserLibraryFolder' -Kind 'DeleteKey' -Key 'HKCR\UserLibraryFolder\shellex\ContextMenuHandlers\SendTo')
        )
    }

    return @(
        (New-BoostLabContextMenuOperation -Id 'ClassicContextMenu' -Kind 'DeleteKey' -Key 'HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}')
        (New-BoostLabContextMenuOperation -Id 'NoCustomizeThisFolder' -Kind 'DeleteValue' -Key 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'NoCustomizeThisFolder')
        (New-BoostLabContextMenuOperation -Id 'PinAndFavoritesDefaults' -Kind 'ImportDefaultFile')
        (New-BoostLabContextMenuOperation -Id 'Compatibility' -Kind 'Add' -Key 'HKCR\exefile\shellex\ContextMenuHandlers\Compatibility' -ValueType 'REG_SZ' -Data '{1d27f844-3a1f-4410-85ac-14651078412d}')
        (New-BoostLabContextMenuOperation -Id 'BlockedShellExtensions' -Kind 'DeleteKey' -Key $script:BoostLabBlockedKey)
        (New-BoostLabContextMenuOperation -Id 'LibraryLocation' -Kind 'Add' -Key 'HKCR\Folder\ShellEx\ContextMenuHandlers\Library Location' -ValueType 'REG_SZ' -Data '{3dad6c5d-2167-4cae-9914-f99e41c12cfa}')
        (New-BoostLabContextMenuOperation -Id 'ModernSharing' -Kind 'Add' -Key 'HKCR\AllFilesystemObjects\shellex\ContextMenuHandlers\ModernSharing' -ValueType 'REG_SZ' -Data '{e2bf9676-5f8f-435c-97eb-11607a5bedf7}')
        (New-BoostLabContextMenuOperation -Id 'PreviousVersions' -Kind 'DeleteValue' -Key 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'NoPreviousVersionsPage')
        (New-BoostLabContextMenuOperation -Id 'SendToAllFilesystemObjects' -Kind 'Add' -Key 'HKCR\AllFilesystemObjects\shellex\ContextMenuHandlers\SendTo' -ValueType 'REG_SZ' -Data '{7BA4C740-9E81-11CF-99D3-00AA004AE837}')
        (New-BoostLabContextMenuOperation -Id 'SendToUserLibraryFolder' -Kind 'Add' -Key 'HKCR\UserLibraryFolder\shellex\ContextMenuHandlers\SendTo' -ValueType 'REG_SZ' -Data '{7BA4C740-9E81-11CF-99D3-00AA004AE837}')
    )
}

function New-BoostLabContextMenuDefinition {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateSet('DWord', 'String', 'KeyAbsent')]
        [string]$ValueType,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Expected
    )

    return [pscustomobject]@{
        Path      = $Path
        Name      = $Name
        ValueType = $ValueType
        Expected  = $Expected
    }
}

function Get-BoostLabContextMenuDefinitions {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName
    )

    $hkcr = 'Registry::HKEY_CLASSES_ROOT'
    if ($ActionName -eq 'Apply') {
        return @(
            (New-BoostLabContextMenuDefinition -Path 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' -Name '(default)' -ValueType 'String' -Expected '')
            (New-BoostLabContextMenuDefinition -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'NoCustomizeThisFolder' -ValueType 'DWord' -Expected '0x00000001')
            (New-BoostLabContextMenuDefinition -Path "$hkcr\Folder\shell\pintohome" -Name '(key)' -ValueType 'KeyAbsent' -Expected 'Absent')
            (New-BoostLabContextMenuDefinition -Path "$hkcr\*\shell\pintohomefile" -Name '(key)' -ValueType 'KeyAbsent' -Expected 'Absent')
            (New-BoostLabContextMenuDefinition -Path "$hkcr\exefile\shellex\ContextMenuHandlers\Compatibility" -Name '(key)' -ValueType 'KeyAbsent' -Expected 'Absent')
            (New-BoostLabContextMenuDefinition -Path $script:BoostLabBlockedRegistryPath -Name $script:BoostLabOwnedBlockedGuids[0] -ValueType 'String' -Expected '')
            (New-BoostLabContextMenuDefinition -Path $script:BoostLabBlockedRegistryPath -Name $script:BoostLabOwnedBlockedGuids[1] -ValueType 'String' -Expected '')
            (New-BoostLabContextMenuDefinition -Path $script:BoostLabBlockedRegistryPath -Name $script:BoostLabOwnedBlockedGuids[2] -ValueType 'String' -Expected '')
            (New-BoostLabContextMenuDefinition -Path "$hkcr\Folder\ShellEx\ContextMenuHandlers\Library Location" -Name '(key)' -ValueType 'KeyAbsent' -Expected 'Absent')
            (New-BoostLabContextMenuDefinition -Path "$hkcr\AllFilesystemObjects\shellex\ContextMenuHandlers\ModernSharing" -Name '(key)' -ValueType 'KeyAbsent' -Expected 'Absent')
            (New-BoostLabContextMenuDefinition -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'NoPreviousVersionsPage' -ValueType 'DWord' -Expected '0x00000001')
            (New-BoostLabContextMenuDefinition -Path "$hkcr\AllFilesystemObjects\shellex\ContextMenuHandlers\SendTo" -Name '(key)' -ValueType 'KeyAbsent' -Expected 'Absent')
            (New-BoostLabContextMenuDefinition -Path "$hkcr\UserLibraryFolder\shellex\ContextMenuHandlers\SendTo" -Name '(key)' -ValueType 'KeyAbsent' -Expected 'Absent')
        )
    }

    return @(
        (New-BoostLabContextMenuDefinition -Path 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}' -Name '(key)' -ValueType 'KeyAbsent' -Expected 'Absent')
        (New-BoostLabContextMenuDefinition -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'NoCustomizeThisFolder' -ValueType 'String' -Expected 'Absent')
        (New-BoostLabContextMenuDefinition -Path "$hkcr\Folder\shell\pintohome" -Name 'AppliesTo' -ValueType 'String' -Expected 'System.ParsingName:<>"::{f874310e-b6b7-47dc-bc84-b9e6b38f5903}" AND System.ParsingName:<>"::{679f85cb-0220-4080-b29b-5540cc05aab6}" AND System.IsFolder:=System.StructuredQueryType.Boolean#True')
        (New-BoostLabContextMenuDefinition -Path "$hkcr\Folder\shell\pintohome" -Name 'CommandStateHandler' -ValueType 'String' -Expected '{b455f46e-e4af-4035-b0a4-cf18d2f6f28e}')
        (New-BoostLabContextMenuDefinition -Path "$hkcr\Folder\shell\pintohome" -Name 'CommandStateSync' -ValueType 'String' -Expected '')
        (New-BoostLabContextMenuDefinition -Path "$hkcr\Folder\shell\pintohome" -Name 'MUIVerb' -ValueType 'String' -Expected '@shell32.dll,-51601')
        (New-BoostLabContextMenuDefinition -Path "$hkcr\Folder\shell\pintohome" -Name 'SkipCloudDownload' -ValueType 'DWord' -Expected '0x00000000')
        (New-BoostLabContextMenuDefinition -Path "$hkcr\Folder\shell\pintohome\command" -Name 'DelegateExecute' -ValueType 'String' -Expected '{b455f46e-e4af-4035-b0a4-cf18d2f6f28e}')
        (New-BoostLabContextMenuDefinition -Path "$hkcr\*\shell\pintohomefile" -Name 'CommandStateHandler' -ValueType 'String' -Expected '{b455f46e-e4af-4035-b0a4-cf18d2f6f28e}')
        (New-BoostLabContextMenuDefinition -Path "$hkcr\*\shell\pintohomefile" -Name 'CommandStateSync' -ValueType 'String' -Expected '')
        (New-BoostLabContextMenuDefinition -Path "$hkcr\*\shell\pintohomefile" -Name 'MUIVerb' -ValueType 'String' -Expected '@shell32.dll,-51608')
        (New-BoostLabContextMenuDefinition -Path "$hkcr\*\shell\pintohomefile" -Name 'NeverDefault' -ValueType 'String' -Expected '')
        (New-BoostLabContextMenuDefinition -Path "$hkcr\*\shell\pintohomefile" -Name 'SkipCloudDownload' -ValueType 'DWord' -Expected '0x00000000')
        (New-BoostLabContextMenuDefinition -Path "$hkcr\*\shell\pintohomefile\command" -Name 'DelegateExecute' -ValueType 'String' -Expected '{b455f46e-e4af-4035-b0a4-cf18d2f6f28e}')
        (New-BoostLabContextMenuDefinition -Path "$hkcr\exefile\shellex\ContextMenuHandlers\Compatibility" -Name '(default)' -ValueType 'String' -Expected '{1d27f844-3a1f-4410-85ac-14651078412d}')
        (New-BoostLabContextMenuDefinition -Path $script:BoostLabBlockedRegistryPath -Name '(key)' -ValueType 'KeyAbsent' -Expected 'Absent')
        (New-BoostLabContextMenuDefinition -Path "$hkcr\Folder\ShellEx\ContextMenuHandlers\Library Location" -Name '(default)' -ValueType 'String' -Expected '{3dad6c5d-2167-4cae-9914-f99e41c12cfa}')
        (New-BoostLabContextMenuDefinition -Path "$hkcr\AllFilesystemObjects\shellex\ContextMenuHandlers\ModernSharing" -Name '(default)' -ValueType 'String' -Expected '{e2bf9676-5f8f-435c-97eb-11607a5bedf7}')
        (New-BoostLabContextMenuDefinition -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' -Name 'NoPreviousVersionsPage' -ValueType 'String' -Expected 'Absent')
        (New-BoostLabContextMenuDefinition -Path "$hkcr\AllFilesystemObjects\shellex\ContextMenuHandlers\SendTo" -Name '(default)' -ValueType 'String' -Expected '{7BA4C740-9E81-11CF-99D3-00AA004AE837}')
        (New-BoostLabContextMenuDefinition -Path "$hkcr\UserLibraryFolder\shellex\ContextMenuHandlers\SendTo" -Name '(default)' -ValueType 'String' -Expected '{7BA4C740-9E81-11CF-99D3-00AA004AE837}')
    )
}

function ConvertTo-BoostLabContextMenuDisplayValue {
    param(
        [AllowNull()]
        [object]$Value,

        [Parameter(Mandatory)]
        [ValidateSet('DWord', 'String')]
        [string]$ValueType
    )

    if ($null -eq $Value) {
        return 'Absent'
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

function Get-BoostLabContextMenuRegistryState {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Definition,

        [scriptblock]$RegistryReader = {
            param($Path, $Name, $ValueType)
            $keyExists = Test-Path -LiteralPath $Path -PathType Container
            if ($ValueType -eq 'KeyAbsent') {
                return [pscustomobject]@{
                    ReadSucceeded = $true
                    KeyExists     = $keyExists
                    Exists        = $keyExists
                    Value         = $null
                    DisplayValue  = if ($keyExists) { 'Present' } else { 'Absent' }
                    Message       = if ($keyExists) { 'Registry key detected.' } else { 'Registry key is absent.' }
                }
            }
            if (-not $keyExists) {
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
                DisplayValue  = ConvertTo-BoostLabContextMenuDisplayValue -Value $property.Value -ValueType $ValueType
                Message       = 'Registry value detected.'
            }
        }
    )

    try {
        $results = @(& $RegistryReader $Definition.Path $Definition.Name $Definition.ValueType)
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

    $applyDefinitions = @(Get-BoostLabContextMenuDefinitions -ActionName 'Apply')
    $defaultDefinitions = @(Get-BoostLabContextMenuDefinitions -ActionName 'Default')
    $applyMatches = 0
    foreach ($definition in $applyDefinitions) {
        $state = Get-BoostLabContextMenuRegistryState -Definition $definition
        if (
            [bool]$state.ReadSucceeded -and
            (
                ($definition.Expected -eq 'Absent' -and -not [bool]$state.Exists) -or
                ([bool]$state.Exists -and [string]$state.DisplayValue -eq [string]$definition.Expected)
            )
        ) {
            $applyMatches++
        }
    }
    $defaultMatches = 0
    foreach ($definition in $defaultDefinitions) {
        $state = Get-BoostLabContextMenuRegistryState -Definition $definition
        if (
            [bool]$state.ReadSucceeded -and
            (
                ($definition.Expected -eq 'Absent' -and -not [bool]$state.Exists) -or
                ([bool]$state.Exists -and [string]$state.DisplayValue -eq [string]$definition.Expected)
            )
        ) {
            $defaultMatches++
        }
    }
    $status = if ($applyMatches -eq $applyDefinitions.Count) {
        'Clean'
    }
    elseif ($defaultMatches -eq $defaultDefinitions.Count) {
        'Default'
    }
    else {
        'Custom or unavailable'
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

function Test-BoostLabContextMenuState {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [scriptblock]$RegistryReader = {
            param($Path, $Name, $ValueType)
            $definition = [pscustomobject]@{ Path = $Path; Name = $Name; ValueType = $ValueType }
            Get-BoostLabContextMenuRegistryState -Definition $definition
        }
    )

    $checks = [System.Collections.Generic.List[object]]::new()
    foreach ($definition in @(Get-BoostLabContextMenuDefinitions -ActionName $ActionName)) {
        try {
            $stateResults = @(& $RegistryReader $definition.Path $definition.Name $definition.ValueType)
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
            'The registry state could not be read.'
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
        $checkName = if ($definition.ValueType -eq 'KeyAbsent') {
            [string]$definition.Path
        }
        else {
            '{0}\{1}' -f $definition.Path, $definition.Name
        }

        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name $checkName `
                -Expected ([string]$definition.Expected) `
                -Actual $actual `
                -Status $status `
                -Message $stateMessage)
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
        'Clean context menu'
    }
    else {
        'Default context menu with source Blocked key removed'
    }
    $detectedState = if ($overallStatus -eq 'Passed') {
        $expectedState
    }
    elseif ($overallStatus -eq 'Warning') {
        'Partially detected'
    }
    else {
        'Unexpected context menu registry state'
    }
    $message = switch ($overallStatus) {
        'Passed' { 'The expected Context Menu registry state was detected.' }
        'Warning' { 'The command completed, but one or more Context Menu registry states could not be detected.' }
        default { 'The detected Context Menu registry state does not match the expected result.' }
    }

    return New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action $ActionName `
        -Status $overallStatus `
        -ExpectedState ([pscustomobject]@{ ContextMenu = $expectedState }) `
        -DetectedState ([pscustomobject]@{ ContextMenu = $detectedState }) `
        -Checks $checks.ToArray() `
        -Message $message
}

function Invoke-BoostLabContextMenuAction {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [scriptblock]$AdministratorChecker = {
            Test-BoostLabAdministrator
        },

        [scriptblock]$RegistryCommandRunner = {
            param($Operation)
            $commandProcessorPath = Join-Path $env:SystemRoot 'System32\cmd.exe'
            $valueSelector = if ([string]::IsNullOrEmpty([string]$Operation.Name)) {
                '/ve'
            }
            else {
                '/v "{0}"' -f [string]$Operation.Name
            }
            $command = switch ([string]$Operation.Kind) {
                'Add' {
                    'reg add "{0}" {1} /t {2} /d "{3}" /f' -f `
                        $Operation.Key, $valueSelector, $Operation.ValueType, $Operation.Data
                }
                'DeleteKey' {
                    'reg delete "{0}" /f' -f $Operation.Key
                }
                'DeleteValue' {
                    'reg delete "{0}" /v "{1}" /f' -f $Operation.Key, $Operation.Name
                }
            }
            $output = & $commandProcessorPath /d /c $command 2>&1
            return [pscustomobject]@{
                Success  = $LASTEXITCODE -eq 0
                ExitCode = $LASTEXITCODE
                Command  = $command
                Message  = (@($output) -join ' ').Trim()
            }
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
            $definition = [pscustomobject]@{ Path = $Path; Name = $Name; ValueType = $ValueType }
            Get-BoostLabContextMenuRegistryState -Definition $definition
        }
    )

    if (-not [bool](& $AdministratorChecker)) {
        return New-BoostLabContextMenuResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Administrator rights are required to modify the approved Context Menu registry state.'
    }
    if ([string]::IsNullOrWhiteSpace($env:SystemRoot)) {
        return New-BoostLabContextMenuResult `
            -Success $false `
            -Action $ActionName `
            -Message 'The Windows system directory is unavailable.'
    }

    $operations = @(Get-BoostLabContextMenuOperations -ActionName $ActionName)
    $operationStatuses = [System.Collections.Generic.List[object]]::new()
    $operationWarnings = [System.Collections.Generic.List[string]]::new()
    $fatalErrors = [System.Collections.Generic.List[string]]::new()
    $registryFilePath = if ($ActionName -eq 'Default') {
        Join-Path (Join-Path $env:SystemRoot 'Temp') 'contextmenudefault.reg'
    }
    else {
        ''
    }
    $registryFileStatus = if ($ActionName -eq 'Default') { 'Pending' } else { 'Not applicable' }
    $registryImportStatus = if ($ActionName -eq 'Default') { 'Pending' } else { 'Not applicable' }

    foreach ($operation in $operations) {
        if ($operation.Kind -eq 'ImportDefaultFile') {
            try {
                $content = Get-BoostLabContextMenuDefaultRegistryContent
                & $FileWriter $registryFilePath $content | Out-Null
                $registryFileStatus = 'Written'
                & $RegistryImporter $registryFilePath | Out-Null
                $registryImportStatus = 'Completed'
                $operationStatuses.Add([pscustomobject]@{
                    Id = $operation.Id; Kind = $operation.Kind; Status = 'Completed'; ExitCode = 0
                })
            }
            catch {
                if ($registryFileStatus -eq 'Pending') {
                    $registryFileStatus = 'Failed'
                    $registryImportStatus = 'Not attempted'
                }
                else {
                    $registryImportStatus = 'Failed'
                }
                $fatalErrors.Add("Default registry import failed: $($_.Exception.Message)")
                $operationStatuses.Add([pscustomobject]@{
                    Id = $operation.Id; Kind = $operation.Kind; Status = 'Failed'; ExitCode = $null
                })
            }
            continue
        }

        try {
            $runnerResults = @(& $RegistryCommandRunner $operation)
            if ($runnerResults.Count -eq 0 -or $null -eq $runnerResults[0]) {
                throw 'Registry command runner returned no result.'
            }
            $runnerResult = $runnerResults[0]
            $success = (
                $null -ne $runnerResult.PSObject.Properties['Success'] -and
                [bool]$runnerResult.Success
            )
            $exitCode = if ($null -ne $runnerResult.PSObject.Properties['ExitCode']) {
                $runnerResult.ExitCode
            }
            else {
                $null
            }
            $operationStatuses.Add([pscustomobject]@{
                Id = $operation.Id
                Kind = $operation.Kind
                Status = if ($success) { 'Completed' } else { 'Reported failure; verification required' }
                ExitCode = $exitCode
            })
            if (-not $success) {
                $message = if ($null -ne $runnerResult.PSObject.Properties['Message']) {
                    [string]$runnerResult.Message
                }
                else {
                    'Registry command reported a non-zero exit code.'
                }
                $operationWarnings.Add("$($operation.Id): $message")
            }
        }
        catch {
            $operationWarnings.Add("$($operation.Id): $($_.Exception.Message)")
            $operationStatuses.Add([pscustomobject]@{
                Id = $operation.Id; Kind = $operation.Kind
                Status = 'Exception; verification required'; ExitCode = $null
            })
        }
    }

    $verificationResult = Test-BoostLabContextMenuState `
        -ActionName $ActionName `
        -RegistryReader $RegistryReader
    $verificationPassed = $verificationResult.Status -eq 'Passed'
    if ($operationWarnings.Count -gt 0 -and -not $verificationPassed) {
        $fatalErrors.Add(
            'One or more registry commands reported failure and the expected state could not be verified.'
        )
    }
    if ($verificationResult.Status -eq 'Failed') {
        $fatalErrors.Add('Verification detected registry state that contradicts the expected result.')
    }

    $commandStatus = if ($fatalErrors.Count -gt 0) {
        'Failed'
    }
    elseif ($operationWarnings.Count -gt 0) {
        'Completed; delete targets verified despite command warnings'
    }
    else {
        'Completed'
    }
    $data = [pscustomobject]@{
        CommandStatus            = $commandStatus
        ExpectedContextMenuState = [string]$verificationResult.ExpectedState.ContextMenu
        DetectedContextMenuState = [string]$verificationResult.DetectedState.ContextMenu
        RegistryStatesChecked    = @(
            $verificationResult.Checks | ForEach-Object { [string]$_.Name }
        )
        RegistryOperations       = $operationStatuses.ToArray()
        RegistryOperationWarnings = $operationWarnings.ToArray()
        RegistryFilePath         = $registryFilePath
        RegistryFileStatus       = $registryFileStatus
        RegistryImportStatus     = $registryImportStatus
        UiRefreshStatus          = 'Not performed by the Ultimate source'
        CompletedAt              = Get-Date
    }

    if ($fatalErrors.Count -gt 0) {
        return New-BoostLabContextMenuResult `
            -Success $false `
            -Action $ActionName `
            -Message ("Context Menu action failed: {0}" -f ($fatalErrors -join '; ')) `
            -Data $data `
            -VerificationResult $verificationResult
    }

    $message = if ($verificationResult.Status -eq 'Warning') {
        'Context Menu command completed, but verification was incomplete.'
    }
    elseif ($ActionName -eq 'Apply') {
        'Clean context menu applied.'
    }
    else {
        'Context menu restored to the approved default.'
    }

    return New-BoostLabContextMenuResult `
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
        return New-BoostLabContextMenuResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Unsupported action. Only Apply and Default are allowed.'
    }
    if (-not $Confirmed) {
        return New-BoostLabContextMenuResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Cancelled by user' `
            -Cancelled $true
    }

    return Invoke-BoostLabContextMenuAction -ActionName $ActionName
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
