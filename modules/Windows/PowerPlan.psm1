Set-StrictMode -Version Latest

$verificationModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1'
if (-not (Get-Command -Name 'New-BoostLabVerificationResult' -ErrorAction SilentlyContinue)) {
    Import-Module -Name $verificationModulePath -Scope Local -ErrorAction Stop
}
$sourceToleratedOutcomeModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\SourceToleratedOutcomes.psm1'
if (-not (Get-Command -Name 'New-BoostLabSourceToleratedOutcomeNote' -ErrorAction SilentlyContinue)) {
    Import-Module -Name $sourceToleratedOutcomeModulePath -Scope Local -Force -ErrorAction Stop
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'power-plan'; Title = 'Power Plan'; Stage = 'Windows'; Order = 20
    Type = 'action'; RiskLevel = 'medium'
    Description = 'Apply the approved Ultimate power configuration or restore Windows default power schemes.'
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
$script:BoostLabUltimateSchemeGuid = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
$script:BoostLabPowerSchemeGuid = '99999999-9999-9999-9999-999999999999'
$script:BoostLabBalancedSchemeGuid = '381b4222-f694-41f0-9685-ff5bb260df2e'
$script:BoostLabHardwareSpecificPowerSettingNames = @(
    'Intel graphics power plan'
    'AMD power slider overlay'
    'ATI PowerPlay'
    'Switchable dynamic graphics'
)

$script:BoostLabPowerSettingDefinitions = @(
    [pscustomobject]@{ Name = 'Turn off hard disk after'; Subgroup = '0012ee47-9041-4b5d-9b77-535fba8b1442'; Setting = '6738e2c4-e8a5-4a42-b16a-e040e769756e'; AC = '0x00000000'; DC = '0x00000000' }
    [pscustomobject]@{ Name = 'Desktop slideshow'; Subgroup = '0d7dbae2-4294-402a-ba8e-26777e8488cd'; Setting = '309dce9b-bef4-4119-9921-a851fb12f0f4'; AC = '001'; DC = '001' }
    [pscustomobject]@{ Name = 'Wireless adapter power saving'; Subgroup = '19cbb8fa-5279-450e-9fac-8a3d5fedd0c1'; Setting = '12bbebe6-58d6-4636-95bb-3217ef867c1a'; AC = '000'; DC = '000' }
    [pscustomobject]@{ Name = 'Sleep after'; Subgroup = '238c9fa8-0aad-41ed-83f4-97be242c8f20'; Setting = '29f6c1db-86da-48c5-9fdb-f2b67b1f44da'; AC = '0x00000000'; DC = '0x00000000' }
    [pscustomobject]@{ Name = 'Allow hybrid sleep'; Subgroup = '238c9fa8-0aad-41ed-83f4-97be242c8f20'; Setting = '94ac6d29-73ce-41a6-809f-6363ba21b47e'; AC = '000'; DC = '000' }
    [pscustomobject]@{ Name = 'Hibernate after'; Subgroup = '238c9fa8-0aad-41ed-83f4-97be242c8f20'; Setting = '9d7815a6-7ee4-497e-8888-515a05f02364'; AC = '0x00000000'; DC = '0x00000000' }
    [pscustomobject]@{ Name = 'Allow wake timers'; Subgroup = '238c9fa8-0aad-41ed-83f4-97be242c8f20'; Setting = 'bd3b718a-0680-4d9d-8ab2-e1d2b4ac806d'; AC = '000'; DC = '000' }
    [pscustomobject]@{ Name = 'USB hub selective suspend timeout'; Subgroup = '2a737441-1930-4402-8d77-b2bebba308a3'; Setting = '0853a681-27c8-4100-a2fd-82013e970683'; AC = '0x00000000'; DC = '0x00000000'; AttributePath = 'System\ControlSet001\Control\Power\PowerSettings\2a737441-1930-4402-8d77-b2bebba308a3\0853a681-27c8-4100-a2fd-82013e970683' }
    [pscustomobject]@{ Name = 'USB selective suspend'; Subgroup = '2a737441-1930-4402-8d77-b2bebba308a3'; Setting = '48e6b7a6-50f5-4782-a5d4-53bb8f07e226'; AC = '000'; DC = '000' }
    [pscustomobject]@{ Name = 'USB 3 link power management'; Subgroup = '2a737441-1930-4402-8d77-b2bebba308a3'; Setting = 'd4e98f31-5ffe-4ce1-be31-1b38b384c009'; AC = '000'; DC = '000'; AttributePath = 'System\ControlSet001\Control\Power\PowerSettings\2a737441-1930-4402-8d77-b2bebba308a3\d4e98f31-5ffe-4ce1-be31-1b38b384c009' }
    [pscustomobject]@{ Name = 'Start menu power button'; Subgroup = '4f971e89-eebd-4455-a8de-9e59040e7347'; Setting = 'a7066653-8d6c-40a8-910e-a1f54b84c7e5'; AC = '002'; DC = '002' }
    [pscustomobject]@{ Name = 'PCI Express link state power management'; Subgroup = '501a4d13-42af-4429-9fd1-a8218c268e20'; Setting = 'ee12f906-d277-404b-b6da-e5fa1a576df5'; AC = '000'; DC = '000' }
    [pscustomobject]@{ Name = 'Minimum processor state'; Subgroup = '54533251-82be-4824-96c1-47b60b740d00'; Setting = '893dee8e-2bef-41e0-89c6-b55d0929964c'; AC = '0x00000064'; DC = '0x00000064' }
    [pscustomobject]@{ Name = 'System cooling policy'; Subgroup = '54533251-82be-4824-96c1-47b60b740d00'; Setting = '94d3a615-a899-4ac5-ae2b-e4d8f634367f'; AC = '001'; DC = '001' }
    [pscustomobject]@{ Name = 'Maximum processor state'; Subgroup = '54533251-82be-4824-96c1-47b60b740d00'; Setting = 'bc5038f7-23e0-4960-96da-33abaf5935ec'; AC = '0x00000064'; DC = '0x00000064' }
    [pscustomobject]@{ Name = 'Processor core parking minimum cores'; Subgroup = '54533251-82be-4824-96c1-47b60b740d00'; Setting = '0cc5b647-c1df-4637-891a-dec35c318583'; AC = '0x00000064'; DC = '0x00000064'; AttributePath = 'System\ControlSet001\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583' }
    [pscustomobject]@{ Name = 'Processor core parking maximum cores'; Subgroup = '54533251-82be-4824-96c1-47b60b740d00'; Setting = 'ea062031-0e34-4ff1-9b6d-eb1059334028'; AC = '0x00000064'; DC = '0x00000064'; AttributePath = 'System\ControlSet001\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\ea062031-0e34-4ff1-9b6d-eb1059334028' }
    [pscustomobject]@{ Name = 'Turn off display after'; Subgroup = '7516b95f-f776-4464-8c53-06167f40cc99'; Setting = '3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e'; AC = '600'; DC = '600' }
    [pscustomobject]@{ Name = 'Display brightness'; Subgroup = '7516b95f-f776-4464-8c53-06167f40cc99'; Setting = 'aded5e82-b909-4619-9949-f5d71dac0bcb'; AC = '0x00000064'; DC = '0x00000064' }
    [pscustomobject]@{ Name = 'Dimmed display brightness'; Subgroup = '7516b95f-f776-4464-8c53-06167f40cc99'; Setting = 'f1fbfde2-a960-4165-9f88-50667911ce96'; AC = '0x00000064'; DC = '0x00000064' }
    [pscustomobject]@{ Name = 'Adaptive brightness'; Subgroup = '7516b95f-f776-4464-8c53-06167f40cc99'; Setting = 'fbd9aa66-9553-4097-ba44-ed6e9d65eab8'; AC = '000'; DC = '000' }
    [pscustomobject]@{ Name = 'Video playback quality bias'; Subgroup = '9596fb26-9850-41fd-ac3e-f7c3c00afd4b'; Setting = '10778347-1370-4ee0-8bbd-33bdacaade49'; AC = '001'; DC = '001' }
    [pscustomobject]@{ Name = 'When playing video'; Subgroup = '9596fb26-9850-41fd-ac3e-f7c3c00afd4b'; Setting = '34c7b99f-9a6d-4b3c-8dc7-b6693b78cef4'; AC = '000'; DC = '000' }
    [pscustomobject]@{ Name = 'Intel graphics power plan'; Subgroup = '44f3beca-a7c0-460e-9df2-bb8b99e0cba6'; Setting = '3619c3f2-afb2-4afc-b0e9-e7fef372de36'; AC = '002'; DC = '002' }
    [pscustomobject]@{ Name = 'AMD power slider overlay'; Subgroup = 'c763b4ec-0e50-4b6b-9bed-2b92a6ee884e'; Setting = '7ec1751b-60ed-4588-afb5-9819d3d77d90'; AC = '003'; DC = '003' }
    [pscustomobject]@{ Name = 'ATI PowerPlay'; Subgroup = 'f693fb01-e858-4f00-b20f-f30e12ac06d6'; Setting = '191f65b5-d45c-4a4f-8aae-1ab8bfd980e6'; AC = '001'; DC = '001' }
    [pscustomobject]@{ Name = 'Switchable dynamic graphics'; Subgroup = 'e276e160-7cb0-43c6-b20b-73f5dce39954'; Setting = 'a1662ab2-9d34-4e53-ba8b-2639b9e20857'; AC = '003'; DC = '003' }
    [pscustomobject]@{ Name = 'Critical battery notification'; Subgroup = 'e73a048d-bf27-4f12-9731-8b2076e8891f'; Setting = '5dbb7c9f-38e9-40d2-9749-4f8a0e9f640f'; AC = '000'; DC = '000' }
    [pscustomobject]@{ Name = 'Critical battery action'; Subgroup = 'e73a048d-bf27-4f12-9731-8b2076e8891f'; Setting = '637ea02f-bbcb-4015-8e2c-a1c7b9c0b546'; AC = '000'; DC = '000' }
    [pscustomobject]@{ Name = 'Low battery level'; Subgroup = 'e73a048d-bf27-4f12-9731-8b2076e8891f'; Setting = '8183ba9a-e910-48da-8769-14ae6dc1170a'; AC = '0x00000000'; DC = '0x00000000' }
    [pscustomobject]@{ Name = 'Critical battery level'; Subgroup = 'e73a048d-bf27-4f12-9731-8b2076e8891f'; Setting = '9a66d8d7-4ff7-4ef9-b5a2-5a326ca2a469'; AC = '0x00000000'; DC = '0x00000000' }
    [pscustomobject]@{ Name = 'Low battery notification'; Subgroup = 'e73a048d-bf27-4f12-9731-8b2076e8891f'; Setting = 'bcded951-187b-4d05-bccc-f7e51960c258'; AC = '000'; DC = '000' }
    [pscustomobject]@{ Name = 'Low battery action'; Subgroup = 'e73a048d-bf27-4f12-9731-8b2076e8891f'; Setting = 'd8742dcb-3e6a-4b3c-b3fe-374623cdcf06'; AC = '000'; DC = '000' }
    [pscustomobject]@{ Name = 'Reserve battery level'; Subgroup = 'e73a048d-bf27-4f12-9731-8b2076e8891f'; Setting = 'f3c5027d-cd16-4930-aa6b-90db844a8f00'; AC = '0x00000000'; DC = '0x00000000' }
    [pscustomobject]@{ Name = 'Battery saver screen brightness'; Subgroup = 'de830923-a562-41af-a086-e3a2c6bad2da'; Setting = '13d09884-f74e-474a-a852-b6bde8ad03a8'; AC = '0x00000064'; DC = '0x00000064' }
    [pscustomobject]@{ Name = 'Battery saver threshold'; Subgroup = 'de830923-a562-41af-a086-e3a2c6bad2da'; Setting = 'e69653ca-cf7f-4f05-aa73-cb833fa90ad4'; AC = '0x00000000'; DC = '0x00000000' }
)

$script:BoostLabApplyRegistryOperations = @(
    [pscustomobject]@{ Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Power'; SubPath = 'SYSTEM\CurrentControlSet\Control\Power'; Name = 'HibernateEnabled'; Value = 0; Type = 'REG_DWORD' }
    [pscustomobject]@{ Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Power'; SubPath = 'SYSTEM\CurrentControlSet\Control\Power'; Name = 'HibernateEnabledDefault'; Value = 0; Type = 'REG_DWORD' }
    [pscustomobject]@{ Path = 'HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings'; SubPath = 'Software\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings'; Name = 'ShowLockOption'; Value = 0; Type = 'REG_DWORD' }
    [pscustomobject]@{ Path = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings'; SubPath = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings'; Name = 'ShowSleepOption'; Value = 0; Type = 'REG_DWORD' }
    [pscustomobject]@{ Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power'; SubPath = 'SYSTEM\CurrentControlSet\Control\Session Manager\Power'; Name = 'HiberbootEnabled'; Value = 0; Type = 'REG_DWORD' }
    [pscustomobject]@{ Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling'; SubPath = 'SYSTEM\CurrentControlSet\Control\Power\PowerThrottling'; Name = 'PowerThrottlingOff'; Value = 1; Type = 'REG_DWORD' }
)

$script:BoostLabDefaultRegistryOperations = @(
    [pscustomobject]@{ Kind = 'DeleteValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Power'; Name = 'HibernateEnabled' }
    [pscustomobject]@{ Kind = 'SetValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Power'; Name = 'HibernateEnabledDefault'; Value = 1; Type = 'REG_DWORD' }
    [pscustomobject]@{ Kind = 'DeleteKey'; Path = 'HKLM\Software\Microsoft\Windows\CurrentVersion\Explorer\FlyoutMenuSettings'; Name = '' }
    [pscustomobject]@{ Kind = 'SetValue'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power'; Name = 'HiberbootEnabled'; Value = 1; Type = 'REG_DWORD' }
    [pscustomobject]@{ Kind = 'DeleteKey'; Path = 'HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling'; Name = '' }
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

function ConvertTo-BoostLabPowerIndex {
    param([Parameter(Mandatory)][string]$Value)

    if ($Value.StartsWith('0x', [StringComparison]::OrdinalIgnoreCase)) {
        return [Convert]::ToUInt32($Value.Substring(2), 16)
    }

    return [Convert]::ToUInt32($Value, 10)
}

function Resolve-BoostLabPowerPlanMessage {
    param(
        [AllowNull()]
        [object]$Message,

        [string]$Fallback = 'Power Plan operation completed.'
    )

    $text = if ($null -eq $Message) { '' } else { [string]$Message }
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $Fallback
    }

    return $text
}

function ConvertTo-BoostLabCommandResult {
    param(
        [AllowNull()][object]$Result,
        [string]$FallbackMessage = 'The command returned no result.'
    )

    $safeFallbackMessage = Resolve-BoostLabPowerPlanMessage `
        -Message $FallbackMessage `
        -Fallback 'The command returned no result.'

    if ($null -eq $Result) {
        return [pscustomobject]@{ Succeeded = $false; ExitCode = $null; Output = @(); Message = $safeFallbackMessage }
    }
    if ($Result -is [bool]) {
        return [pscustomobject]@{
            Succeeded = [bool]$Result
            ExitCode  = if ($Result) { 0 } else { 1 }
            Output    = @()
            Message   = if ($Result) { 'Command completed.' } else { $safeFallbackMessage }
        }
    }

    $resultMessage = if ($null -ne $Result.PSObject.Properties['Message']) {
        [string]$Result.Message
    }
    else {
        $safeFallbackMessage
    }

    return [pscustomobject]@{
        Succeeded = if ($null -ne $Result.PSObject.Properties['Succeeded']) { [bool]$Result.Succeeded } else { $false }
        ExitCode  = if ($null -ne $Result.PSObject.Properties['ExitCode']) { $Result.ExitCode } else { $null }
        Output    = if ($null -ne $Result.PSObject.Properties['Output']) { @($Result.Output) } else { @() }
        Message   = Resolve-BoostLabPowerPlanMessage -Message $resultMessage -Fallback $safeFallbackMessage
    }
}

function Get-BoostLabPowerSettingDefinitionByGuid {
    param([Parameter(Mandatory)][string]$SettingGuid)

    return @($script:BoostLabPowerSettingDefinitions |
        Where-Object { [string]$_.Setting -eq $SettingGuid } |
        Select-Object -First 1)
}

function New-BoostLabPowerWarningDetail {
    param(
        [Parameter(Mandatory)][string]$Category,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Description,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Message,
        [AllowEmptyString()][string]$SettingName = '',
        [string[]]$Arguments = @()
    )

    return [pscustomobject]@{
        Category = $Category
        Description = $Description
        Message = $Message
        SettingName = $SettingName
        Arguments = @($Arguments)
    }
}

function Get-BoostLabPowerCfgCompatibilityWarningDetail {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments,

        [Parameter(Mandatory)]
        [object]$Result,

        [AllowEmptyString()]
        [string]$Description = ''
    )

    $notWarning = [pscustomobject]@{ IsWarning = $false; Detail = $null }
    if ([bool]$Result.Succeeded -or $Arguments.Count -eq 0) {
        return $notWarning
    }

    $commandName = ([string]$Arguments[0]).ToLowerInvariant()
    $diagnosticText = @(
        [string]$Result.Message
        @($Result.Output | ForEach-Object { [string]$_ })
    ) -join ' '

    if (
        $commandName -eq '/duplicatescheme' -and
        $Arguments.Count -gt 2 -and
        [string]$Arguments[1] -eq $script:BoostLabUltimateSchemeGuid -and
        [string]$Arguments[2] -eq $script:BoostLabPowerSchemeGuid -and
        $diagnosticText -match '(?i)(scheme\s+could\s+not\s+be\s+duplicated\s+because\s+)?a?\s*power\s+scheme\s+with\s+the\s+specified\s+GUID\s+already\s+exists'
    ) {
        return [pscustomobject]@{
            IsWarning = $true
            Detail = New-BoostLabPowerWarningDetail -Category 'ExistingTargetSchemeReuse' -Description $Description -Message ([string]$Result.Message) -Arguments $Arguments
        }
    }

    if (
        $commandName -eq '/delete' -and
        $Arguments.Count -gt 1 -and
        [string]$Arguments[1] -eq $script:BoostLabPowerSchemeGuid -and
        $diagnosticText -match '(?i)\bactive\s+(power\s+scheme|plan)\s+cannot\s+be\s+deleted\b'
    ) {
        return [pscustomobject]@{
            IsWarning = $true
            Detail = New-BoostLabPowerWarningDetail -Category 'ActiveSchemeDeleteAttemptExpected' -Description $Description -Message ([string]$Result.Message) -Arguments $Arguments
        }
    }

    if ($commandName -notin @('/setacvalueindex', '/setdcvalueindex')) {
        return $notWarning
    }

    $isUnsupportedSetting = (
        $diagnosticText -match '(?i)the\s+power\s+scheme,\s*subgroup\s+or\s+setting\s+specified\s+does\s+not\s+exist' -or
        $diagnosticText -match '(?i)\b(power\s+)?setting\b.*\b(unavailable|unsupported|not\s+supported|does\s+not\s+exist)\b' -or
        $diagnosticText -match '(?i)\b(unavailable|unsupported|not\s+supported)\b.*\b(power\s+)?setting\b' -or
        $diagnosticText -match '(?i)powercfg\s+output\s+did\s+not\s+expose\s+readable\s+AC\s+and\s+DC\s+indexes'
    )
    if (-not $isUnsupportedSetting) {
        return $notWarning
    }

    $settingName = ''
    if ($Arguments.Count -gt 3) {
        $definition = @(Get-BoostLabPowerSettingDefinitionByGuid -SettingGuid ([string]$Arguments[3]))
        if ($definition.Count -gt 0) {
            $settingName = [string]$definition[0].Name
        }
    }
    $category = if ($settingName -in $script:BoostLabHardwareSpecificPowerSettingNames) {
        'HardwareSpecificUnsupportedSetting'
    }
    else {
        'UnsupportedPowerCfgSetting'
    }

    return [pscustomobject]@{
        IsWarning = $true
        Detail = New-BoostLabPowerWarningDetail -Category $category -Description $Description -Message ([string]$Result.Message) -SettingName $settingName -Arguments $Arguments
    }
}

function Test-BoostLabPowerCfgCompatibilityWarning {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments,

        [Parameter(Mandatory)]
        [object]$Result
    )

    $classification = Get-BoostLabPowerCfgCompatibilityWarningDetail -Arguments $Arguments -Result $Result
    return [bool]$classification.IsWarning
}

function Get-BoostLabPowerSettingNameFromCheck {
    param([Parameter(Mandatory)][object]$Check)

    $name = [string]$Check.Name
    if ($name -match '^Power setting \| (?<SettingName>.+?) \| ') {
        return [string]$Matches.SettingName
    }

    return ''
}

function Get-BoostLabPowerPlanWarningSummary {
    param(
        [object[]]$CommandWarnings = @(),
        [AllowNull()][object]$VerificationResult = $null,
        [string[]]$Errors = @()
    )

    $checks = if ($null -ne $VerificationResult -and $null -ne $VerificationResult.PSObject.Properties['Checks']) {
        @($VerificationResult.Checks)
    }
    else {
        @()
    }

    $activeCheck = @($checks | Where-Object { [string]$_.Name -eq 'Active power plan GUID' } | Select-Object -First 1)
    $activePlanVerified = $activeCheck.Count -gt 0 -and [string]$activeCheck[0].Status -eq 'Passed'
    $powerSettingChecks = @($checks | Where-Object { [string]$_.Name -like 'Power setting | *' })
    $passedSettingCount = @($powerSettingChecks | Where-Object { [string]$_.Status -eq 'Passed' }).Count

    $hardwareNames = [System.Collections.Generic.List[string]]::new()
    $unreadableWarnings = [System.Collections.Generic.List[string]]::new()
    $otherWarnings = [System.Collections.Generic.List[string]]::new()

    foreach ($warning in @($CommandWarnings)) {
        $category = [string]$warning.Category
        $settingName = [string]$warning.SettingName
        if ($category -eq 'HardwareSpecificUnsupportedSetting') {
            if (-not [string]::IsNullOrWhiteSpace($settingName) -and $settingName -notin $hardwareNames) {
                $hardwareNames.Add($settingName)
            }
            continue
        }
        elseif ($category -eq 'UnsupportedPowerCfgSetting') {
            continue
        }
        elseif ($category -notin @('ActiveSchemeDeleteAttemptExpected', 'ExistingTargetSchemeReuse')) {
            $text = [string]$warning.Description
            if ([string]::IsNullOrWhiteSpace($text)) { $text = [string]$warning.Message }
            if (-not [string]::IsNullOrWhiteSpace($text)) { $otherWarnings.Add($text) }
        }
    }

    foreach ($check in @($checks | Where-Object { [string]$_.Status -eq 'Warning' })) {
        $settingName = Get-BoostLabPowerSettingNameFromCheck -Check $check
        if ($settingName -in $script:BoostLabHardwareSpecificPowerSettingNames) {
            if ($settingName -notin $hardwareNames) {
                $hardwareNames.Add($settingName)
            }
            continue
        }

        if (
            [string]$check.Message -match '(?i)powercfg\s+output\s+did\s+not\s+expose\s+readable\s+AC\s+and\s+DC\s+indexes' -or
            [string]$check.Message -match '(?i)\b(unavailable|unsupported|not\s+supported|does\s+not\s+exist)\b'
        ) {
            $unreadableWarnings.Add([string]$check.Name)
        }
        else {
            $otherWarnings.Add([string]$check.Name)
        }
    }

    $activeDeleteWarning = @($CommandWarnings | Where-Object { [string]$_.Category -eq 'ActiveSchemeDeleteAttemptExpected' } | Select-Object -First 1)
    $failedChecks = @($checks | Where-Object { [string]$_.Status -eq 'Failed' })
    $unexpectedFailures = [System.Collections.Generic.List[string]]::new()
    foreach ($errorText in @($Errors)) {
        if (-not [string]::IsNullOrWhiteSpace([string]$errorText)) {
            $unexpectedFailures.Add([string]$errorText)
        }
    }
    foreach ($check in $failedChecks) {
        $unexpectedFailures.Add(('{0}: {1}' -f [string]$check.Name, [string]$check.Message))
    }

    $finalStatusReason = if ($unexpectedFailures.Count -gt 0) {
        'UnexpectedPowerCfgFailure'
    }
    elseif ($activePlanVerified -and ($hardwareNames.Count -gt 0 -or $unreadableWarnings.Count -gt 0 -or $otherWarnings.Count -gt 0 -or $activeDeleteWarning.Count -gt 0)) {
        'ActivePlanVerifiedWithCompatibilityWarnings'
    }
    elseif ($hardwareNames.Count -gt 0 -or $unreadableWarnings.Count -gt 0 -or $otherWarnings.Count -gt 0 -or $activeDeleteWarning.Count -gt 0) {
        'CompletedWithCompatibilityWarnings'
    }
    else {
        'CompletedWithoutWarnings'
    }

    return [pscustomobject]@{
        FinalStatusReason = $finalStatusReason
        ActivePlanVerified = $activePlanVerified
        PassedSettingCount = $passedSettingCount
        HardwareSpecificUnsupportedSettingCount = $hardwareNames.Count
        HardwareSpecificUnsupportedSettings = $hardwareNames.ToArray()
        ExpectedActiveSchemeDeleteWarning = if ($activeDeleteWarning.Count -gt 0) { [string]$activeDeleteWarning[0].Description } else { '' }
        UnreadablePowerCfgIndexWarningCount = $unreadableWarnings.Count
        UnreadablePowerCfgIndexWarnings = $unreadableWarnings.ToArray()
        OtherCompatibilityWarningCount = $otherWarnings.Count
        OtherCompatibilityWarnings = $otherWarnings.ToArray()
        UnexpectedFailureCount = $unexpectedFailures.Count
        UnexpectedFailures = $unexpectedFailures.ToArray()
    }
}

function Invoke-BoostLabPowerCfgCommand {
    param([Parameter(Mandatory)][string[]]$Arguments)

    if ([string]::IsNullOrWhiteSpace($env:SystemRoot)) {
        return [pscustomobject]@{ Succeeded = $false; ExitCode = $null; Output = @(); Message = 'The Windows system directory is unavailable.' }
    }
    $path = Join-Path $env:SystemRoot 'System32\powercfg.exe'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return [pscustomobject]@{ Succeeded = $false; ExitCode = $null; Output = @(); Message = 'powercfg.exe was not found.' }
    }

    try {
        $output = @(& $path @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
        return [pscustomobject]@{
            Succeeded = $exitCode -eq 0
            ExitCode  = $exitCode
            Output    = $output
            Message   = if ($exitCode -eq 0) { 'powercfg command completed.' } else { Resolve-BoostLabPowerPlanMessage -Message ((@($output) -join ' ').Trim()) -Fallback "powercfg exited with code $exitCode." }
        }
    }
    catch {
        return [pscustomobject]@{ Succeeded = $false; ExitCode = $null; Output = @(); Message = $_.Exception.Message }
    }
}

function Invoke-BoostLabPowerPlanRegistryCommand {
    param([Parameter(Mandatory)][string[]]$Arguments)

    if ([string]::IsNullOrWhiteSpace($env:SystemRoot)) {
        return [pscustomobject]@{ Succeeded = $false; ExitCode = $null; Output = @(); Message = 'The Windows system directory is unavailable.' }
    }
    $path = Join-Path $env:SystemRoot 'System32\reg.exe'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return [pscustomobject]@{ Succeeded = $false; ExitCode = $null; Output = @(); Message = 'reg.exe was not found.' }
    }

    try {
        $output = @(& $path @Arguments 2>&1)
        $exitCode = $LASTEXITCODE
        return [pscustomobject]@{
            Succeeded = $exitCode -eq 0
            ExitCode  = $exitCode
            Output    = $output
            Message   = if ($exitCode -eq 0) { 'Registry command completed.' } else { Resolve-BoostLabPowerPlanMessage -Message ((@($output) -join ' ').Trim()) -Fallback "reg.exe exited with code $exitCode." }
        }
    }
    catch {
        return [pscustomobject]@{ Succeeded = $false; ExitCode = $null; Output = @(); Message = $_.Exception.Message }
    }
}

function Get-BoostLabPowerPlanInventory {
    param(
        [scriptblock]$PowerCfgInvoker = {
            param($Arguments)
            Invoke-BoostLabPowerCfgCommand -Arguments $Arguments
        }
    )

    $raw = @(& $PowerCfgInvoker -Arguments @('/list'))
    $result = ConvertTo-BoostLabCommandResult -Result $(if ($raw.Count -gt 0) { $raw[0] } else { $null })
    if (-not $result.Succeeded) {
        return [pscustomobject]@{
            Succeeded = $false
            Plans      = @()
            ActiveGuid = ''
            Message    = "Power plan enumeration failed: $($result.Message)"
        }
    }

    $plans = [System.Collections.Generic.List[object]]::new()
    foreach ($line in @($result.Output)) {
        $text = [string]$line
        if ($text -match '(?i)(?<Guid>[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})') {
            $guid = $Matches.Guid.ToLowerInvariant()
            if ($guid -notin @($plans | ForEach-Object { $_.Guid })) {
                $plans.Add([pscustomobject]@{
                    Guid     = $guid
                    IsActive = $text.Contains('*')
                    RawLine  = $text
                })
            }
        }
    }
    $activePlan = @($plans | Where-Object IsActive | Select-Object -First 1)
    return [pscustomobject]@{
        Succeeded = $true
        Plans      = $plans.ToArray()
        ActiveGuid = if ($activePlan.Count -gt 0) { [string]$activePlan[0].Guid } else { '' }
        Message    = '{0} power plan(s) detected.' -f $plans.Count
    }
}

function Get-BoostLabPowerSettingState {
    param(
        [Parameter(Mandatory)][string]$SchemeGuid,
        [Parameter(Mandatory)][string]$SubgroupGuid,
        [Parameter(Mandatory)][string]$SettingGuid,
        [scriptblock]$PowerCfgInvoker = {
            param($Arguments)
            Invoke-BoostLabPowerCfgCommand -Arguments $Arguments
        }
    )

    $raw = @(& $PowerCfgInvoker -Arguments @('/query', $SchemeGuid, $SubgroupGuid, $SettingGuid))
    $result = ConvertTo-BoostLabCommandResult -Result $(if ($raw.Count -gt 0) { $raw[0] } else { $null })
    if (-not $result.Succeeded) {
        return [pscustomobject]@{
            Succeeded = $false; Supported = $false; ACValue = $null; DCValue = $null
            Message = $result.Message
        }
    }

    $matches = @(
        [regex]::Matches((@($result.Output) -join [Environment]::NewLine), '(?i)0x[0-9a-f]{8}') |
            ForEach-Object { $_.Value }
    )
    if ($matches.Count -lt 2) {
        return [pscustomobject]@{
            Succeeded = $true; Supported = $false; ACValue = $null; DCValue = $null
            Message = 'powercfg output did not expose readable AC and DC indexes.'
        }
    }

    return [pscustomobject]@{
        Succeeded = $true
        Supported = $true
        ACValue   = ConvertTo-BoostLabPowerIndex -Value $matches[$matches.Count - 2]
        DCValue   = ConvertTo-BoostLabPowerIndex -Value $matches[$matches.Count - 1]
        Message   = 'Power setting indexes detected.'
    }
}

function Get-BoostLabPowerPlanRegistryValue {
    param(
        [Parameter(Mandatory)][string]$SubPath,
        [Parameter(Mandatory)][string]$Name
    )

    $baseKey = $null
    $key = $null
    try {
        $baseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey(
            [Microsoft.Win32.RegistryHive]::LocalMachine,
            [Microsoft.Win32.RegistryView]::Default
        )
        $key = $baseKey.OpenSubKey($SubPath, $false)
        if ($null -eq $key) {
            return [pscustomobject]@{ ReadSucceeded = $true; Exists = $false; Value = $null; DisplayValue = 'Absent'; Message = 'Registry key is absent.' }
        }
        if ($Name -notin @($key.GetValueNames())) {
            return [pscustomobject]@{ ReadSucceeded = $true; Exists = $false; Value = $null; DisplayValue = 'Absent'; Message = 'Registry value is absent.' }
        }
        $value = $key.GetValue($Name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        return [pscustomobject]@{ ReadSucceeded = $true; Exists = $true; Value = $value; DisplayValue = [string]$value; Message = 'Registry value detected read-only.' }
    }
    catch {
        return [pscustomobject]@{ ReadSucceeded = $false; Exists = $false; Value = $null; DisplayValue = 'Unknown'; Message = $_.Exception.Message }
    }
    finally {
        if ($null -ne $key) { $key.Dispose() }
        if ($null -ne $baseKey) { $baseKey.Dispose() }
    }
}

function Get-BoostLabPowerPlanRegistryVerificationDefinitions {
    param([Parameter(Mandatory)][ValidateSet('Apply', 'Default')][string]$ActionName)

    $definitions = [System.Collections.Generic.List[object]]::new()
    foreach ($operation in $script:BoostLabApplyRegistryOperations) {
        $expectedExists = $true
        $expectedValue = $operation.Value
        if ($ActionName -eq 'Default') {
            switch ($operation.Name) {
                'HibernateEnabled' { $expectedExists = $false; $expectedValue = $null }
                'HibernateEnabledDefault' { $expectedValue = 1 }
                'ShowLockOption' { $expectedExists = $false; $expectedValue = $null }
                'ShowSleepOption' { $expectedExists = $false; $expectedValue = $null }
                'HiberbootEnabled' { $expectedValue = 1 }
                'PowerThrottlingOff' { $expectedExists = $false; $expectedValue = $null }
            }
        }
        $definitions.Add([pscustomobject]@{
            Path = $operation.Path; SubPath = $operation.SubPath; Name = $operation.Name
            ExpectedExists = $expectedExists; ExpectedValue = $expectedValue
        })
    }
    foreach ($definition in @($script:BoostLabPowerSettingDefinitions | Where-Object { $_.PSObject.Properties['AttributePath'] })) {
        $definitions.Add([pscustomobject]@{
            Path = "HKLM\$($definition.AttributePath)"
            SubPath = [string]$definition.AttributePath
            Name = 'Attributes'
            ExpectedExists = $true
            ExpectedValue = if ($ActionName -eq 'Apply') { 0 } else { 1 }
        })
    }
    return $definitions.ToArray()
}

function New-BoostLabPowerPlanResult {
    param(
        [Parameter(Mandatory)][bool]$Success,
        [Parameter(Mandatory)][string]$Action,
        [Parameter(Mandatory)][AllowNull()][AllowEmptyString()][string]$Message,
        [bool]$Cancelled = $false,
        [AllowNull()][object]$Data = $null,
        [AllowNull()][object]$VerificationResult = $null
    )

    $status = if ($Cancelled) {
        'Cancelled'
    }
    elseif (-not $Success) {
        'Failed'
    }
    elseif (
        ($null -ne $VerificationResult -and [string]$VerificationResult.Status -eq 'Warning') -or
        ($null -ne $Data -and [string]$Data.CommandStatus -eq 'Completed with warnings')
    ) {
        'Warning'
    }
    else {
        'Passed'
    }

    return [pscustomobject]@{
        Success = $Success; ToolId = 'power-plan'; ToolTitle = 'Power Plan'; Action = $Action
        Status = $status
        Message = (Resolve-BoostLabPowerPlanMessage -Message $Message); RestartRequired = $false; Cancelled = $Cancelled; Timestamp = Get-Date
        Data = $Data; VerificationResult = $VerificationResult
    }
}

function Get-BoostLabToolInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        Id = [string]$script:BoostLabToolMetadata.Id
        Title = [string]$script:BoostLabToolMetadata.Title
        Stage = [string]$script:BoostLabToolMetadata.Stage
        Order = [int]$script:BoostLabToolMetadata.Order
        Type = [string]$script:BoostLabToolMetadata.Type
        RiskLevel = [string]$script:BoostLabToolMetadata.RiskLevel
        Description = [string]$script:BoostLabToolMetadata.Description
        Actions = @($script:BoostLabToolMetadata.Actions)
        Capabilities = [pscustomobject]$script:BoostLabToolMetadata.Capabilities
        ImplementedActions = @($script:BoostLabImplementedActions)
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([string]$OperatingSystem = $env:OS, [string]$SystemRoot = $env:SystemRoot)

    $powerCfgPath = if ([string]::IsNullOrWhiteSpace($SystemRoot)) { '' } else { Join-Path $SystemRoot 'System32\powercfg.exe' }
    $supported = $OperatingSystem -eq 'Windows_NT' -and -not [string]::IsNullOrWhiteSpace($powerCfgPath) -and (Test-Path -LiteralPath $powerCfgPath -PathType Leaf)
    return [pscustomobject]@{
        Supported = $supported; ToolId = 'power-plan'; ToolTitle = 'Power Plan'
        Reason = if ($supported) { 'Windows powercfg support is available.' } else { 'Power Plan requires Windows and powercfg.exe.' }
        Timestamp = Get-Date
    }
}

function Test-BoostLabPowerPlanState {
    param(
        [Parameter(Mandatory)][ValidateSet('Apply', 'Default')][string]$ActionName,
        [scriptblock]$PlanInventoryReader = { Get-BoostLabPowerPlanInventory },
        [scriptblock]$PowerSettingReader = {
            param($SchemeGuid, $SubgroupGuid, $SettingGuid)
            Get-BoostLabPowerSettingState -SchemeGuid $SchemeGuid -SubgroupGuid $SubgroupGuid -SettingGuid $SettingGuid
        },
        [scriptblock]$RegistryReader = {
            param($SubPath, $Name)
            Get-BoostLabPowerPlanRegistryValue -SubPath $SubPath -Name $Name
        },
        [string[]]$ExpectedDeletedPlanGuids = @()
    )

    $checks = [System.Collections.Generic.List[object]]::new()
    $inventoryRaw = @(& $PlanInventoryReader)
    $inventory = if ($inventoryRaw.Count -gt 0) { $inventoryRaw[0] } else { $null }
    $expectedActive = if ($ActionName -eq 'Apply') { $script:BoostLabPowerSchemeGuid } else { $script:BoostLabBalancedSchemeGuid }
    if ($null -eq $inventory -or -not [bool]$inventory.Succeeded) {
        $checks.Add((New-BoostLabVerificationCheck -Name 'Active power plan GUID' -Expected $expectedActive -Actual 'Unavailable' -Status 'Warning' -Message (Resolve-BoostLabPowerPlanMessage -Message $(if ($null -ne $inventory) { [string]$inventory.Message } else { $null }) -Fallback 'Power plan inventory returned no result.')))
    }
    else {
        $activeStatus = if ([string]$inventory.ActiveGuid -eq $expectedActive) { 'Passed' } else { 'Failed' }
        $checks.Add((New-BoostLabVerificationCheck -Name 'Active power plan GUID' -Expected $expectedActive -Actual ([string]$inventory.ActiveGuid) -Status $activeStatus -Message 'Active plan detected with powercfg /list.'))
        if ($ActionName -eq 'Apply') {
            foreach ($guid in @($ExpectedDeletedPlanGuids | Where-Object { $_ -ne $script:BoostLabPowerSchemeGuid } | Sort-Object -Unique)) {
                $exists = $guid -in @($inventory.Plans | ForEach-Object { [string]$_.Guid })
                $checks.Add((New-BoostLabVerificationCheck -Name "Deleted power plan | $guid" -Expected 'Absent' -Actual $(if ($exists) { 'Present' } else { 'Absent' }) -Status $(if ($exists) { 'Failed' } else { 'Passed' }) -Message 'Ultimate deletes every enumerated non-active scheme.'))
            }
        }
        else {
            $customExists = $script:BoostLabPowerSchemeGuid -in @($inventory.Plans | ForEach-Object { [string]$_.Guid })
            $checks.Add((New-BoostLabVerificationCheck -Name 'BoostLab Ultimate scheme after Default' -Expected 'Absent' -Actual $(if ($customExists) { 'Present' } else { 'Absent' }) -Status $(if ($customExists) { 'Failed' } else { 'Passed' }) -Message 'restoredefaultschemes should remove custom schemes.'))
        }
    }

    if ($ActionName -eq 'Apply') {
        foreach ($definition in $script:BoostLabPowerSettingDefinitions) {
            $stateRaw = @(& $PowerSettingReader $script:BoostLabPowerSchemeGuid ([string]$definition.Subgroup) ([string]$definition.Setting))
            $state = if ($stateRaw.Count -gt 0) { $stateRaw[0] } else { $null }
            $expectedAC = ConvertTo-BoostLabPowerIndex -Value ([string]$definition.AC)
            $expectedDC = ConvertTo-BoostLabPowerIndex -Value ([string]$definition.DC)
            $readable = $null -ne $state -and [bool]$state.Succeeded -and [bool]$state.Supported
            $status = if (-not $readable) {
                'Warning'
            }
            elseif ([uint32]$state.ACValue -eq $expectedAC -and [uint32]$state.DCValue -eq $expectedDC) {
                'Passed'
            }
            else {
                'Failed'
            }
            $actual = if ($readable) { 'AC={0}; DC={1}' -f $state.ACValue, $state.DCValue } else { 'Unavailable or unsupported' }
            $checks.Add((New-BoostLabVerificationCheck -Name ("Power setting | {0} | {1}\{2}" -f $definition.Name, $definition.Subgroup, $definition.Setting) -Expected ("AC={0}; DC={1}" -f $expectedAC, $expectedDC) -Actual $actual -Status $status -Message (Resolve-BoostLabPowerPlanMessage -Message $(if ($null -ne $state) { [string]$state.Message } else { $null }) -Fallback 'Power setting reader returned no result.')))
        }
    }

    foreach ($definition in @(Get-BoostLabPowerPlanRegistryVerificationDefinitions -ActionName $ActionName)) {
        $stateRaw = @(& $RegistryReader ([string]$definition.SubPath) ([string]$definition.Name))
        $state = if ($stateRaw.Count -gt 0) { $stateRaw[0] } else { $null }
        $readable = $null -ne $state -and [bool]$state.ReadSucceeded
        $exists = $readable -and [bool]$state.Exists
        $status = if (-not $readable) {
            'Warning'
        }
        elseif (-not [bool]$definition.ExpectedExists -and -not $exists) {
            'Passed'
        }
        elseif ([bool]$definition.ExpectedExists -and $exists -and [string]$state.Value -eq [string]$definition.ExpectedValue) {
            'Passed'
        }
        else {
            'Failed'
        }
        $checks.Add((New-BoostLabVerificationCheck -Name ("Registry | {0}\{1}" -f $definition.Path, $definition.Name) -Expected $(if ($definition.ExpectedExists) { [string]$definition.ExpectedValue } else { 'Absent' }) -Actual $(if ($null -ne $state) { [string]$state.DisplayValue } else { 'Unknown' }) -Status $status -Message (Resolve-BoostLabPowerPlanMessage -Message $(if ($null -ne $state) { [string]$state.Message } else { $null }) -Fallback 'Registry reader returned no result.')))
    }

    $failed = @($checks | Where-Object Status -eq 'Failed').Count
    $warnings = @($checks | Where-Object Status -eq 'Warning').Count
    $passed = @($checks | Where-Object Status -eq 'Passed').Count
    $status = if ($failed -gt 0) { 'Failed' } elseif ($warnings -gt 0) { 'Warning' } else { 'Passed' }
    $expectedSummary = if ($ActionName -eq 'Apply') { "Ultimate scheme $script:BoostLabPowerSchemeGuid active with 36 approved settings" } else { "Windows default schemes restored with Balanced $script:BoostLabBalancedSchemeGuid active" }
    $detectedSummary = '{0} passed, {1} warning, {2} failed' -f $passed, $warnings, $failed
    return New-BoostLabVerificationResult -ToolId 'power-plan' -ToolTitle 'Power Plan' -Action $ActionName -Status $status -ExpectedState ([pscustomobject]@{ PowerPlan = $expectedSummary }) -DetectedState ([pscustomobject]@{ PowerPlan = $detectedSummary }) -Checks $checks.ToArray() -Message $(switch ($status) { 'Passed' { 'The expected Power Plan state was detected.' } 'Warning' { 'The Power Plan command completed, but one or more settings were unavailable or unsupported.' } default { 'One or more detected Power Plan states contradict the expected state.' } })
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $inventory = Get-BoostLabPowerPlanInventory
    return [pscustomobject]@{
        ToolId = 'power-plan'; ToolTitle = 'Power Plan'
        Status = if ($inventory.Succeeded) { "Active plan: $($inventory.ActiveGuid)" } else { 'Power plan unavailable' }
        ActivePowerPlanGuid = [string]$inventory.ActiveGuid
        LastAction = $null; LastResult = $null; RestartRequired = $false; Timestamp = Get-Date
    }
}

function Invoke-BoostLabPowerPlanAction {
    param(
        [Parameter(Mandatory)][ValidateSet('Apply', 'Default')][string]$ActionName,
        [scriptblock]$AdministratorChecker = { Test-BoostLabAdministrator },
        [scriptblock]$PowerCfgInvoker = {
            param($Arguments)
            Invoke-BoostLabPowerCfgCommand -Arguments $Arguments
        },
        [scriptblock]$RegistryInvoker = {
            param($Arguments)
            Invoke-BoostLabPowerPlanRegistryCommand -Arguments $Arguments
        },
        [scriptblock]$PlanInventoryReader = { Get-BoostLabPowerPlanInventory },
        [scriptblock]$VerificationPlanInventoryReader = { Get-BoostLabPowerPlanInventory },
        [scriptblock]$PowerSettingReader = {
            param($SchemeGuid, $SubgroupGuid, $SettingGuid)
            Get-BoostLabPowerSettingState -SchemeGuid $SchemeGuid -SubgroupGuid $SubgroupGuid -SettingGuid $SettingGuid
        },
        [scriptblock]$RegistryReader = {
            param($SubPath, $Name)
            Get-BoostLabPowerPlanRegistryValue -SubPath $SubPath -Name $Name
        },
        [scriptblock]$UiLauncher = { Start-Process 'powercfg.cpl' -ErrorAction Stop }
    )

    if (-not [bool](& $AdministratorChecker)) {
        return New-BoostLabPowerPlanResult -Success $false -Action $ActionName -Message 'Administrator rights are required to change the Power Plan.'
    }

    $attempted = [System.Collections.Generic.List[string]]::new()
    $completed = [System.Collections.Generic.List[string]]::new()
    $warnings = [System.Collections.Generic.List[string]]::new()
    $warningDetails = [System.Collections.Generic.List[object]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()
    $targetedGuids = [System.Collections.Generic.List[string]]::new()
    $initialPlanGuids = @()
    $uiStatus = 'Not launched'

    $invokePowerCfg = {
        param([string[]]$Arguments, [string]$Description)
        $attempted.Add($Description)
        $raw = @(& $PowerCfgInvoker -Arguments $Arguments)
        $result = ConvertTo-BoostLabCommandResult -Result $(if ($raw.Count -gt 0) { $raw[0] } else { $null }) -FallbackMessage "$Description returned no result."
        if ($result.Succeeded) {
            $completed.Add($Description)
        }
        else {
            $warningClassification = Get-BoostLabPowerCfgCompatibilityWarningDetail -Arguments $Arguments -Result $result -Description $Description
            if ([bool]$warningClassification.IsWarning) {
                $warnings.Add("${Description}: $($result.Message)")
                $warningDetails.Add($warningClassification.Detail)
            }
            else {
                $errors.Add("${Description}: $($result.Message)")
            }
        }
        return $result
    }
    $invokeRegistry = {
        param([string[]]$Arguments, [string]$Description)
        $attempted.Add($Description)
        $raw = @(& $RegistryInvoker -Arguments $Arguments)
        $result = ConvertTo-BoostLabCommandResult -Result $(if ($raw.Count -gt 0) { $raw[0] } else { $null }) -FallbackMessage "$Description returned no result."
        if ($result.Succeeded) { $completed.Add($Description) } else { $errors.Add("${Description}: $($result.Message)") }
        return $result
    }

    if ($ActionName -eq 'Apply') {
        $duplicateArguments = @('/duplicatescheme', $script:BoostLabUltimateSchemeGuid, $script:BoostLabPowerSchemeGuid)
        $duplicate = & $invokePowerCfg -Arguments $duplicateArguments -Description 'Duplicate Ultimate Performance scheme'
        $reuseExistingTarget = (
            -not [bool]$duplicate.Succeeded -and
            (Test-BoostLabPowerCfgCompatibilityWarning -Arguments $duplicateArguments -Result $duplicate)
        )
        & $invokePowerCfg -Arguments @('/setactive', $script:BoostLabPowerSchemeGuid) -Description 'Activate BoostLab Ultimate scheme' | Out-Null

        $inventoryRaw = @(& $PlanInventoryReader)
        $inventory = if ($inventoryRaw.Count -gt 0) { $inventoryRaw[0] } else { $null }
        if ($null -eq $inventory -or -not [bool]$inventory.Succeeded) {
            $errors.Add($(if ($null -ne $inventory) { [string]$inventory.Message } else { 'Power plan enumeration returned no result.' }))
        }
        else {
            $initialPlanGuids = @($inventory.Plans | ForEach-Object { [string]$_.Guid })
            foreach ($guid in $initialPlanGuids) {
                $targetedGuids.Add($guid)
            }
            if ($reuseExistingTarget -and $script:BoostLabPowerSchemeGuid -notin $initialPlanGuids) {
                $errors.Add(
                    "Duplicate reported that target scheme $script:BoostLabPowerSchemeGuid already exists, but the target scheme was not detected for reuse."
                )
            }
            foreach ($guid in $initialPlanGuids) {
                & $invokePowerCfg -Arguments @('/delete', $guid) -Description "Delete enumerated power scheme $guid" | Out-Null
            }
        }

        & $invokePowerCfg -Arguments @('/hibernate', 'off') -Description 'Disable hibernation' | Out-Null
        foreach ($operation in $script:BoostLabApplyRegistryOperations) {
            & $invokeRegistry -Arguments @('add', [string]$operation.Path, '/v', [string]$operation.Name, '/t', [string]$operation.Type, '/d', [string]$operation.Value, '/f') -Description "Set $($operation.Path)\$($operation.Name)=$($operation.Value)" | Out-Null
        }
        foreach ($definition in $script:BoostLabPowerSettingDefinitions) {
            if ($null -ne $definition.PSObject.Properties['AttributePath']) {
                $path = "HKLM\$($definition.AttributePath)"
                & $invokeRegistry -Arguments @('add', $path, '/v', 'Attributes', '/t', 'REG_DWORD', '/d', '0', '/f') -Description "Set $path\Attributes=0" | Out-Null
            }
            & $invokePowerCfg -Arguments @('/setacvalueindex', $script:BoostLabPowerSchemeGuid, [string]$definition.Subgroup, [string]$definition.Setting, [string]$definition.AC) -Description "Set AC $($definition.Name)" | Out-Null
            & $invokePowerCfg -Arguments @('/setdcvalueindex', $script:BoostLabPowerSchemeGuid, [string]$definition.Subgroup, [string]$definition.Setting, [string]$definition.DC) -Description "Set DC $($definition.Name)" | Out-Null
        }
    }
    else {
        $targetedGuids.Add($script:BoostLabBalancedSchemeGuid)
        $targetedGuids.Add($script:BoostLabPowerSchemeGuid)
        & $invokePowerCfg -Arguments @('-restoredefaultschemes') -Description 'Restore Windows default power schemes' | Out-Null
        & $invokePowerCfg -Arguments @('/hibernate', 'on') -Description 'Enable hibernation' | Out-Null
        foreach ($operation in $script:BoostLabDefaultRegistryOperations) {
            $arguments = if ($operation.Kind -eq 'SetValue') {
                @('add', [string]$operation.Path, '/v', [string]$operation.Name, '/t', [string]$operation.Type, '/d', [string]$operation.Value, '/f')
            }
            elseif ($operation.Kind -eq 'DeleteValue') {
                @('delete', [string]$operation.Path, '/v', [string]$operation.Name, '/f')
            }
            else {
                @('delete', [string]$operation.Path, '/f')
            }
            & $invokeRegistry -Arguments $arguments -Description "$($operation.Kind) $($operation.Path)\$($operation.Name)" | Out-Null
        }
        foreach ($definition in @($script:BoostLabPowerSettingDefinitions | Where-Object { $_.PSObject.Properties['AttributePath'] })) {
            $path = "HKLM\$($definition.AttributePath)"
            & $invokeRegistry -Arguments @('add', $path, '/v', 'Attributes', '/t', 'REG_DWORD', '/d', '1', '/f') -Description "Set $path\Attributes=1" | Out-Null
        }
    }

    try {
        & $UiLauncher | Out-Null
        $uiStatus = 'Power Options launched'
    }
    catch {
        $uiStatus = "Power Options launch warning: $($_.Exception.Message)"
        $warnings.Add($uiStatus)
    }

    $verification = Test-BoostLabPowerPlanState -ActionName $ActionName -PlanInventoryReader $VerificationPlanInventoryReader -PowerSettingReader $PowerSettingReader -RegistryReader $RegistryReader -ExpectedDeletedPlanGuids $initialPlanGuids
    $completedAt = Get-Date
    $registryChecks = @(
        Get-BoostLabPowerPlanRegistryVerificationDefinitions -ActionName $ActionName |
            ForEach-Object { '{0}\{1}' -f $_.Path, $_.Name }
    )
    $powerChecks = @(
        if ($ActionName -eq 'Apply') {
            $script:BoostLabPowerSettingDefinitions | ForEach-Object { '{0}\{1}' -f $_.Subgroup, $_.Setting }
        }
        '/list active scheme'
    )
    $warningSummary = Get-BoostLabPowerPlanWarningSummary -CommandWarnings $warningDetails.ToArray() -VerificationResult $verification -Errors $errors.ToArray()
    $recognizedCompatibilityCategories = @(
        'ActiveSchemeDeleteAttemptExpected'
        'ExistingTargetSchemeReuse'
        'HardwareSpecificUnsupportedSetting'
        'UnsupportedPowerCfgSetting'
    )
    $unclassifiedWarningDetails = @(
        $warningDetails |
            Where-Object { [string]$_.Category -notin $recognizedCompatibilityCategories }
    )
    $sourceToleratedCompatibility = (
        $ActionName -eq 'Apply' -and
        $errors.Count -eq 0 -and
        [bool]$warningSummary.ActivePlanVerified -and
        [int]$warningSummary.UnexpectedFailureCount -eq 0 -and
        [int]$warningSummary.OtherCompatibilityWarningCount -eq 0 -and
        $unclassifiedWarningDetails.Count -eq 0 -and
        $warnings.Count -eq $warningDetails.Count -and
        (
            [int]$warningSummary.HardwareSpecificUnsupportedSettingCount -gt 0 -or
            [int]$warningSummary.UnreadablePowerCfgIndexWarningCount -gt 0 -or
            -not [string]::IsNullOrWhiteSpace([string]$warningSummary.ExpectedActiveSchemeDeleteWarning) -or
            @($warningDetails | Where-Object { [string]$_.Category -eq 'ExistingTargetSchemeReuse' }).Count -gt 0
        )
    )
    $informationalNotes = [System.Collections.Generic.List[object]]::new()
    if ($sourceToleratedCompatibility) {
        foreach ($detail in @($warningDetails)) {
            $reasonCode = switch ([string]$detail.Category) {
                'ActiveSchemeDeleteAttemptExpected' { 'ActiveSchemeDeleteAttemptExpected' }
                'ExistingTargetSchemeReuse' { 'ExistingTargetSchemeReuse' }
                default { 'HardwareSpecificUnsupportedSetting' }
            }
            $messageText = [string]$detail.Description
            if ([string]::IsNullOrWhiteSpace($messageText)) {
                $messageText = [string]$detail.Message
            }
            $informationalNotes.Add(
                (New-BoostLabSourceToleratedOutcomeNote `
                    -ToolId 'power-plan' `
                    -ReasonCode $reasonCode `
                    -Message $messageText `
                    -Details $detail)
            )
        }
        foreach ($settingName in @($warningSummary.HardwareSpecificUnsupportedSettings)) {
            if (@($informationalNotes | Where-Object { [string]$_.Message -like "*$settingName*" }).Count -eq 0) {
                $informationalNotes.Add(
                    (New-BoostLabSourceToleratedOutcomeNote `
                        -ToolId 'power-plan' `
                        -ReasonCode 'HardwareSpecificUnsupportedSetting' `
                        -Message ("Hardware-specific power setting was unavailable: {0}" -f [string]$settingName) `
                        -Details ([pscustomobject]@{ SettingName = [string]$settingName }))
                )
            }
        }
        foreach ($unreadableSetting in @($warningSummary.UnreadablePowerCfgIndexWarnings)) {
            $settingName = [string]$unreadableSetting
            if ($settingName -like 'Power setting | *') {
                $settingNameParts = @($settingName -split '\s+\|\s+', 3)
                if ($settingNameParts.Count -ge 2) {
                    $settingName = [string]$settingNameParts[1]
                }
            }
            if (@($informationalNotes | Where-Object { [string]$_.Message -like "*$settingName*" }).Count -eq 0) {
                $informationalNotes.Add(
                    (New-BoostLabSourceToleratedOutcomeNote `
                        -ToolId 'power-plan' `
                        -ReasonCode 'HardwareSpecificUnsupportedSetting' `
                        -Message ("Power setting index was unavailable or unreadable: {0}" -f [string]$unreadableSetting) `
                        -Details ([pscustomobject]@{ CheckName = [string]$unreadableSetting }))
                )
            }
        }
    }
    $effectiveVerification = $verification
    if ($sourceToleratedCompatibility -and [string]$verification.Status -eq 'Warning') {
        $effectiveVerification = [pscustomobject]@{
            ToolId        = [string]$verification.ToolId
            ToolTitle     = [string]$verification.ToolTitle
            Action        = [string]$verification.Action
            Status        = 'Passed'
            ExpectedState = $verification.ExpectedState
            DetectedState = $verification.DetectedState
            Checks        = @($verification.Checks)
            Message       = 'The expected Power Plan state was detected; source-tolerated compatibility notes were recorded.'
            Timestamp     = $verification.Timestamp
        }
    }
    $commandStatus = if ($errors.Count -gt 0) {
        'Completed with errors'
    }
    elseif ($sourceToleratedCompatibility) {
        'Completed'
    }
    elseif ($warnings.Count -gt 0) {
        'Completed with warnings'
    }
    else {
        'Completed'
    }
    $finalStatusReason = if ($sourceToleratedCompatibility) {
        'ActivePlanVerifiedWithInformationalCompatibility'
    }
    else {
        [string]$warningSummary.FinalStatusReason
    }
    $data = [pscustomobject]@{
        CommandStatus = $commandStatus
        VerificationStatus = [string]$effectiveVerification.Status
        FinalStatusReason = $finalStatusReason
        ActivePlanVerified = [bool]$warningSummary.ActivePlanVerified
        PassedSettingCount = [int]$warningSummary.PassedSettingCount
        HardwareSpecificUnsupportedSettingCount = [int]$warningSummary.HardwareSpecificUnsupportedSettingCount
        HardwareSpecificUnsupportedSettings = @($warningSummary.HardwareSpecificUnsupportedSettings)
        ExpectedActiveSchemeDeleteWarning = [string]$warningSummary.ExpectedActiveSchemeDeleteWarning
        UnreadablePowerCfgIndexWarningCount = [int]$warningSummary.UnreadablePowerCfgIndexWarningCount
        UnreadablePowerCfgIndexWarnings = @($warningSummary.UnreadablePowerCfgIndexWarnings)
        OtherCompatibilityWarningCount = [int]$warningSummary.OtherCompatibilityWarningCount
        OtherCompatibilityWarnings = @($warningSummary.OtherCompatibilityWarnings)
        UnexpectedFailureCount = [int]$warningSummary.UnexpectedFailureCount
        UnexpectedFailures = @($warningSummary.UnexpectedFailures)
        ExpectedPowerPlanState = [string]$verification.ExpectedState.PowerPlan
        DetectedPowerPlanState = [string]$verification.DetectedState.PowerPlan
        PowerPlanGuidsTargeted = $targetedGuids.ToArray()
        PowerCfgCommandsOrSettingsChecked = $powerChecks
        RegistryValuesOrFilesChecked = $registryChecks
        CommandsAttempted = $attempted.ToArray()
        CommandsCompleted = $completed.ToArray()
        Warnings = if ($sourceToleratedCompatibility) { @() } else { $warnings.ToArray() }
        InformationalNotes = $informationalNotes.ToArray()
        ExpectedNoOpOutcomes = $informationalNotes.ToArray()
        WarningClassifications = $warningDetails.ToArray()
        Errors = $errors.ToArray()
        PowerOptionsStatus = $uiStatus
        CompletedAt = $completedAt
    }

    if ($errors.Count -gt 0) {
        return New-BoostLabPowerPlanResult -Success $false -Action $ActionName -Message ('Power Plan action completed with errors: {0}' -f ($errors -join '; ')) -Data $data -VerificationResult $effectiveVerification
    }
    if ($effectiveVerification.Status -eq 'Failed') {
        return New-BoostLabPowerPlanResult -Success $false -Action $ActionName -Message 'Power Plan commands completed, but verification detected an unexpected state.' -Data $data -VerificationResult $effectiveVerification
    }
    $message = if ($sourceToleratedCompatibility) {
        'Ultimate Power Plan applied; expected source-tolerated compatibility notes were recorded in result details.'
    }
    elseif ($effectiveVerification.Status -eq 'Warning' -or $warnings.Count -gt 0) {
        if ([string]$warningSummary.FinalStatusReason -eq 'ActivePlanVerifiedWithCompatibilityWarnings' -and $ActionName -eq 'Apply') {
            'Power Plan applied and the BoostLab Ultimate scheme is active; review expected hardware-specific or unreadable setting warnings.'
        }
        else {
            'Power Plan commands completed with compatibility warnings; review unsupported settings and command details.'
        }
    }
    elseif ($ActionName -eq 'Apply') {
        'Ultimate Power Plan applied.'
    }
    else {
        'Windows default power plans restored.'
    }
    return New-BoostLabPowerPlanResult -Success $true -Action $ActionName -Message $message -Data $data -VerificationResult $effectiveVerification
}

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string]$ActionName,
        [bool]$Confirmed = $false
    )

    if ($ActionName -notin $script:BoostLabImplementedActions) {
        return New-BoostLabPowerPlanResult -Success $false -Action $ActionName -Message 'Unsupported action. Only Apply and Default are allowed.'
    }
    if (-not $Confirmed) {
        return New-BoostLabPowerPlanResult -Success $false -Action $ActionName -Message 'Cancelled by user' -Cancelled $true
    }
    return Invoke-BoostLabPowerPlanAction -ActionName $ActionName
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([bool]$Confirmed = $false)

    return Invoke-BoostLabToolAction -ActionName 'Default' -Confirmed:$Confirmed
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
)
