Set-StrictMode -Version Latest

$verificationModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'core\Verification.psm1'
if (-not (Get-Command -Name 'New-BoostLabVerificationResult' -ErrorAction SilentlyContinue)) {
    Import-Module -Name $verificationModulePath -Scope Local -Force -ErrorAction Stop
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'copilot'; Title = 'Copilot'; Stage = 'Windows'; Order = 8
    Type = 'action'; RiskLevel = 'high'
    Description = 'Run the approved source-equivalent Copilot Off or Default workflow.'
    Actions = @('Apply', 'Default')
    Capabilities = [ordered]@{
        RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false
        CanModifyRegistry = $true; CanModifyServices = $false; CanInstallSoftware = $true
        CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $true
        CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false
        SupportsDefault = $true; SupportsRestore = $false; NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Apply', 'Default')
$script:BoostLabCopilotProcessNames = @(
    'backgroundTaskHost'
    'Copilot'
    'CrossDeviceResume'
    'GameBar'
    'MicrosoftEdgeUpdate'
    'msedge'
    'msedgewebview2'
    'OneDrive'
    'OneDrive.Sync.Service'
    'OneDriveStandaloneUpdater'
    'Resume'
    'RuntimeBroker'
    'Search'
    'SearchHost'
    'Setup'
    'StoreDesktopExtension'
    'WidgetService'
    'Widgets'
)
$script:BoostLabCopilotWildcardProcessPattern = '*edge*'
$script:BoostLabCopilotPackagePattern = '*Copilot*'
$script:BoostLabCopilotValueName = 'TurnOffWindowsCopilot'
$script:BoostLabExpectedSourceHash = '21B58212B241A6C0B74582063E3E74F746014E9137194B58B088CC6692F22A90'
$script:BoostLabExpectedCanonicalSourceHash = '45F87252A018398E87B281DE094E4943A63026567EB0782B631BBEF989CF6A9E'
$script:BoostLabSourceRelativePath = 'source-ultimate\6 Windows\8 Copilot.ps1'
$script:BoostLabCopilotUserPolicyKey = 'HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot'
$script:BoostLabCopilotMachinePolicyKey = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot'
$script:BoostLabCopilotUserPolicyProviderPath = 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot'
$script:BoostLabCopilotMachinePolicyProviderPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot'

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

function New-BoostLabCopilotResult {
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
    $appxCommandsAvailable = (
        $null -ne (Get-Command -Name 'Get-AppxPackage' -ErrorAction SilentlyContinue) -and
        $null -ne (Get-Command -Name 'Remove-AppxPackage' -ErrorAction SilentlyContinue) -and
        $null -ne (Get-Command -Name 'Add-AppxPackage' -ErrorAction SilentlyContinue)
    )
    $supported = (
        $OperatingSystem -eq 'Windows_NT' -and
        $RegistryProviderAvailable -and
        $appxCommandsAvailable -and
        (Test-Path -LiteralPath $commandProcessorPath -PathType Leaf)
    )

    return [pscustomobject]@{
        Supported = $supported
        ToolId    = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle = [string]$script:BoostLabToolMetadata['Title']
        Reason    = if ($OperatingSystem -ne 'Windows_NT') {
            'Copilot source-equivalent behavior requires Windows.'
        }
        elseif (-not $RegistryProviderAvailable) {
            'Copilot is unavailable because the PowerShell Registry provider was not found.'
        }
        elseif (-not $appxCommandsAvailable) {
            'Copilot requires the built-in AppX package cmdlets.'
        }
        elseif (-not $supported) {
            'Copilot requires the built-in cmd.exe registry command path.'
        }
        else {
            'Copilot source-equivalent process, AppX, and policy operations are available.'
        }
        Timestamp = Get-Date
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    return [pscustomobject]@{
        ToolId          = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
        Status          = 'Ready'
        LastAction      = $null
        LastResult      = $null
        RestartRequired = $false
        Timestamp       = Get-Date
    }
}

function Test-BoostLabCopilotSourceIntegrity {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string]$ProjectRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    )

    $sourcePath = Join-Path $ProjectRoot $script:BoostLabSourceRelativePath
    $sourceVerificationModulePath = Join-Path $ProjectRoot 'core\SourceVerification.psm1'
    if (-not (Get-Command -Name 'Test-BoostLabSourceChecksum' -ErrorAction SilentlyContinue)) {
        Import-Module -Name $sourceVerificationModulePath -Scope Local -Force -ErrorAction Stop
    }

    try {
        $verification = Test-BoostLabSourceChecksum -LiteralPath $sourcePath -ExpectedSha256 $script:BoostLabExpectedSourceHash -ExpectedCanonicalSha256 $script:BoostLabExpectedCanonicalSourceHash

        return [pscustomobject]@{
            Valid                 = [string]$verification.ChecksumStatus -eq 'Passed'
            SourcePath            = $sourcePath
            ExpectedHash          = $script:BoostLabExpectedSourceHash
            ActualHash            = [string]$verification.DetectedSha256
            ExpectedCanonicalHash = $script:BoostLabExpectedCanonicalSourceHash
            ActualCanonicalHash   = [string]$verification.DetectedCanonicalSha256
            ChecksumStatus        = [string]$verification.ChecksumStatus
            VerificationMode      = [string]$verification.VerificationMode
            Message               = if (-not [bool]$verification.Exists) {
                'Approved Copilot Ultimate source file was not found.'
            }
            elseif ([string]$verification.ChecksumStatus -eq 'Passed') {
                'Approved Copilot Ultimate source checksum verified.'
            }
            else {
                'Approved Copilot Ultimate source checksum mismatch.'
            }
        }
    }
    catch {
        return [pscustomobject]@{
            Valid                 = $false
            SourcePath            = $sourcePath
            ExpectedHash          = $script:BoostLabExpectedSourceHash
            ActualHash            = ''
            ExpectedCanonicalHash = $script:BoostLabExpectedCanonicalSourceHash
            ActualCanonicalHash   = ''
            ChecksumStatus        = 'Failed'
            VerificationMode      = 'Failed'
            Message               = $_.Exception.Message
        }
    }
}

function New-BoostLabCopilotOperation {
    param(
        [Parameter(Mandatory)]
        [string]$Id,

        [Parameter(Mandatory)]
        [ValidateSet('StopNamedProcesses', 'StopWildcardProcesses', 'RemoveAppxPackages', 'RegisterAppxPackages', 'SetRegistryValue', 'DeleteRegistryKey')]
        [string]$Kind,

        [string[]]$Targets = @(),

        [string]$Pattern = '',

        [string]$Key = '',

        [string]$ProviderPath = '',

        [string]$Name = '',

        [string]$ValueType = '',

        [AllowEmptyString()]
        [string]$Data = '',

        [string]$Command = ''
    )

    return [pscustomobject]@{
        Id           = $Id
        Kind         = $Kind
        Targets      = @($Targets)
        Pattern      = $Pattern
        Key          = $Key
        ProviderPath = $ProviderPath
        Name         = $Name
        ValueType    = $ValueType
        Data         = $Data
        Command      = $Command
    }
}

function Get-BoostLabCopilotOperations {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName
    )

    if ($ActionName -eq 'Apply') {
        return @(
            (New-BoostLabCopilotOperation -Id 'StopSourceNamedProcesses' -Kind 'StopNamedProcesses' -Targets $script:BoostLabCopilotProcessNames)
            (New-BoostLabCopilotOperation -Id 'StopEdgeWildcardProcesses' -Kind 'StopWildcardProcesses' -Pattern $script:BoostLabCopilotWildcardProcessPattern)
            (New-BoostLabCopilotOperation -Id 'RemoveCopilotAppxPackages' -Kind 'RemoveAppxPackages' -Pattern $script:BoostLabCopilotPackagePattern)
            (New-BoostLabCopilotOperation -Id 'SetUserCopilotPolicy' -Kind 'SetRegistryValue' -Key $script:BoostLabCopilotUserPolicyKey -ProviderPath $script:BoostLabCopilotUserPolicyProviderPath -Name $script:BoostLabCopilotValueName -ValueType 'REG_DWORD' -Data '1' -Command 'reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d "1" /f')
            (New-BoostLabCopilotOperation -Id 'SetMachineCopilotPolicy' -Kind 'SetRegistryValue' -Key $script:BoostLabCopilotMachinePolicyKey -ProviderPath $script:BoostLabCopilotMachinePolicyProviderPath -Name $script:BoostLabCopilotValueName -ValueType 'REG_DWORD' -Data '1' -Command 'reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v "TurnOffWindowsCopilot" /t REG_DWORD /d "1" /f')
        )
    }

    return @(
        (New-BoostLabCopilotOperation -Id 'RegisterCopilotAppxPackages' -Kind 'RegisterAppxPackages' -Pattern $script:BoostLabCopilotPackagePattern)
        (New-BoostLabCopilotOperation -Id 'DeleteUserCopilotPolicyKey' -Kind 'DeleteRegistryKey' -Key $script:BoostLabCopilotUserPolicyKey -ProviderPath $script:BoostLabCopilotUserPolicyProviderPath -Command 'reg delete "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /f')
        (New-BoostLabCopilotOperation -Id 'DeleteMachineCopilotPolicyKey' -Kind 'DeleteRegistryKey' -Key $script:BoostLabCopilotMachinePolicyKey -ProviderPath $script:BoostLabCopilotMachinePolicyProviderPath -Command 'reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /f')
    )
}

function Invoke-BoostLabCopilotRegistryCommand {
    param(
        [Parameter(Mandatory)]
        [string]$CommandProcessorPath,

        [Parameter(Mandatory)]
        [string]$CommandText,

        [Parameter(Mandatory)]
        [string]$Description
    )

    $output = & $CommandProcessorPath /c $CommandText 2>&1
    if ($LASTEXITCODE -ne 0) {
        $detail = (@($output) -join ' ').Trim()
        if ([string]::IsNullOrWhiteSpace($detail)) {
            $detail = "reg.exe returned exit code $LASTEXITCODE."
        }

        throw "$Description failed: $detail"
    }
}

function Get-BoostLabCopilotRegistryValue {
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Name
    )

    try {
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
            DisplayValue  = [string]$property.Value
            Message       = 'Registry value detected.'
        }
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

function Get-BoostLabCopilotRegistryKeyState {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    try {
        $exists = Test-Path -LiteralPath $Path -PathType Container
        return [pscustomobject]@{
            ReadSucceeded = $true
            Exists        = $exists
            DisplayValue  = if ($exists) { 'Present' } else { 'Absent' }
            Message       = if ($exists) { 'Registry key exists.' } else { 'Registry key is absent.' }
        }
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

function Get-BoostLabCopilotProcessMatches {
    param(
        [string]$Name = '',

        [string]$Pattern = ''
    )

    try {
        $matches = if (-not [string]::IsNullOrWhiteSpace($Name)) {
            @([System.Diagnostics.Process]::GetProcessesByName($Name))
        }
        else {
            @([System.Diagnostics.Process]::GetProcesses() | Where-Object { $_.ProcessName -like $Pattern })
        }

        return [pscustomobject]@{
            ReadSucceeded = $true
            Count         = $matches.Count
            DisplayValue  = [string]$matches.Count
            Message       = if ($matches.Count -eq 0) { 'No matching processes detected.' } else { "$($matches.Count) matching process(es) detected." }
        }
    }
    catch {
        return [pscustomobject]@{
            ReadSucceeded = $false
            Count         = $null
            DisplayValue  = 'Unknown'
            Message       = $_.Exception.Message
        }
    }
}

function Get-BoostLabCopilotPackageMatches {
    param(
        [Parameter(Mandatory)]
        [string]$Pattern
    )

    try {
        $packages = @(Get-AppxPackage -AllUsers | Where-Object { $_.Name -like $Pattern })
        return [pscustomobject]@{
            ReadSucceeded = $true
            Count         = $packages.Count
            DisplayValue  = [string]$packages.Count
            Message       = if ($packages.Count -eq 0) { 'No matching AppX packages detected.' } else { "$($packages.Count) matching AppX package(s) detected." }
        }
    }
    catch {
        return [pscustomobject]@{
            ReadSucceeded = $false
            Count         = $null
            DisplayValue  = 'Unknown'
            Message       = $_.Exception.Message
        }
    }
}

function Test-BoostLabCopilotState {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [AllowNull()]
        [scriptblock]$RegistryReader = $null,

        [AllowNull()]
        [scriptblock]$RegistryKeyReader = $null,

        [AllowNull()]
        [scriptblock]$ProcessReader = $null,

        [AllowNull()]
        [scriptblock]$AppxReader = $null
    )

    $readRegistry = if ($null -ne $RegistryReader) {
        $RegistryReader
    }
    else {
        { param($Path, $Name) Get-BoostLabCopilotRegistryValue -Path $Path -Name $Name }
    }
    $readRegistryKey = if ($null -ne $RegistryKeyReader) {
        $RegistryKeyReader
    }
    else {
        { param($Path) Get-BoostLabCopilotRegistryKeyState -Path $Path }
    }
    $readProcess = if ($null -ne $ProcessReader) {
        $ProcessReader
    }
    else {
        { param($Name, $Pattern) Get-BoostLabCopilotProcessMatches -Name $Name -Pattern $Pattern }
    }
    $readAppx = if ($null -ne $AppxReader) {
        $AppxReader
    }
    else {
        { param($Pattern) Get-BoostLabCopilotPackageMatches -Pattern $Pattern }
    }

    $checks = [System.Collections.Generic.List[object]]::new()
    if ($ActionName -eq 'Apply') {
        foreach ($registryTarget in @(
            [pscustomobject]@{ Name = 'HKCU WindowsCopilot policy'; Path = $script:BoostLabCopilotUserPolicyProviderPath }
            [pscustomobject]@{ Name = 'HKLM WindowsCopilot policy'; Path = $script:BoostLabCopilotMachinePolicyProviderPath }
        )) {
            $state = & $readRegistry $registryTarget.Path $script:BoostLabCopilotValueName
            $status = if (-not [bool]$state.ReadSucceeded) {
                'Warning'
            }
            elseif (-not [bool]$state.Exists -or [string]$state.Value -ne '1') {
                'Failed'
            }
            else {
                'Passed'
            }
            $checks.Add(
                (New-BoostLabVerificationCheck `
                    -Name $registryTarget.Name `
                    -Expected 'TurnOffWindowsCopilot = REG_DWORD 1' `
                    -Actual ([string]$state.DisplayValue) `
                    -Status $status `
                    -Message ([string]$state.Message))
            )
        }

        foreach ($processName in $script:BoostLabCopilotProcessNames) {
            $state = & $readProcess $processName ''
            $status = if (-not [bool]$state.ReadSucceeded) {
                'Warning'
            }
            elseif ([int]$state.Count -gt 0) {
                'Failed'
            }
            else {
                'Passed'
            }
            $checks.Add(
                (New-BoostLabVerificationCheck `
                    -Name "Process $processName" `
                    -Expected 'Not running' `
                    -Actual ([string]$state.DisplayValue) `
                    -Status $status `
                    -Message ([string]$state.Message))
            )
        }

        $wildcardState = & $readProcess '' $script:BoostLabCopilotWildcardProcessPattern
        $wildcardStatus = if (-not [bool]$wildcardState.ReadSucceeded) {
            'Warning'
        }
        elseif ([int]$wildcardState.Count -gt 0) {
            'Failed'
        }
        else {
            'Passed'
        }
        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name 'Wildcard *edge* process state' `
                -Expected 'No matching processes' `
                -Actual ([string]$wildcardState.DisplayValue) `
                -Status $wildcardStatus `
                -Message ([string]$wildcardState.Message))
        )

        $appxState = & $readAppx $script:BoostLabCopilotPackagePattern
        $appxStatus = if (-not [bool]$appxState.ReadSucceeded) {
            'Warning'
        }
        elseif ([int]$appxState.Count -gt 0) {
            'Failed'
        }
        else {
            'Passed'
        }
        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name 'Copilot AppX package state' `
                -Expected 'No *Copilot* packages' `
                -Actual ([string]$appxState.DisplayValue) `
                -Status $appxStatus `
                -Message ([string]$appxState.Message))
        )
    }
    else {
        foreach ($registryTarget in @(
            [pscustomobject]@{ Name = 'HKCU WindowsCopilot policy key'; Path = $script:BoostLabCopilotUserPolicyProviderPath }
            [pscustomobject]@{ Name = 'HKLM WindowsCopilot policy key'; Path = $script:BoostLabCopilotMachinePolicyProviderPath }
        )) {
            $state = & $readRegistryKey $registryTarget.Path
            $status = if (-not [bool]$state.ReadSucceeded) {
                'Warning'
            }
            elseif ([bool]$state.Exists) {
                'Failed'
            }
            else {
                'Passed'
            }
            $checks.Add(
                (New-BoostLabVerificationCheck `
                    -Name $registryTarget.Name `
                    -Expected 'Absent' `
                    -Actual ([string]$state.DisplayValue) `
                    -Status $status `
                    -Message ([string]$state.Message))
            )
        }

        $appxState = & $readAppx $script:BoostLabCopilotPackagePattern
        $appxStatus = if (-not [bool]$appxState.ReadSucceeded) { 'Warning' } else { 'Passed' }
        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name 'Copilot AppX re-registration check' `
                -Expected 'Re-registration attempted for matching packages' `
                -Actual ([string]$appxState.DisplayValue) `
                -Status $appxStatus `
                -Message ([string]$appxState.Message))
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
    $message = switch ($overallStatus) {
        'Passed' { 'The expected Copilot source-equivalent state was detected.' }
        'Warning' { 'Copilot commands completed, but part of the resulting state could not be confirmed.' }
        default { 'The detected Copilot state does not match the expected result.' }
    }

    return New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action $ActionName `
        -Status $overallStatus `
        -ExpectedState ([pscustomobject]@{
            RegistryPolicy = if ($ActionName -eq 'Apply') { 'HKCU/HKLM TurnOffWindowsCopilot = 1' } else { 'HKCU/HKLM WindowsCopilot keys absent' }
            ProcessState = if ($ActionName -eq 'Apply') { 'Source named and wildcard *edge* processes not running' } else { 'Not applicable' }
            AppxState = if ($ActionName -eq 'Apply') { 'No *Copilot* packages' } else { 'Matching packages re-registered if present' }
        }) `
        -DetectedState ([pscustomobject]@{
            Checks = @($checks | ForEach-Object { '{0}: {1}' -f $_.Name, $_.Actual })
        }) `
        -Checks $checks.ToArray() `
        -Message $message
}

function Invoke-BoostLabCopilotAction {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Apply', 'Default')]
        [string]$ActionName,

        [AllowNull()]
        [scriptblock]$AdministratorChecker = $null,

        [AllowNull()]
        [scriptblock]$NamedProcessStopper = $null,

        [AllowNull()]
        [scriptblock]$WildcardProcessStopper = $null,

        [AllowNull()]
        [scriptblock]$AppxRemover = $null,

        [AllowNull()]
        [scriptblock]$AppxRegistrar = $null,

        [AllowNull()]
        [scriptblock]$RegistryCommandRunner = $null,

        [AllowNull()]
        [scriptblock]$RegistryReader = $null,

        [AllowNull()]
        [scriptblock]$RegistryKeyReader = $null,

        [AllowNull()]
        [scriptblock]$ProcessReader = $null,

        [AllowNull()]
        [scriptblock]$AppxReader = $null
    )

    $sourceIntegrity = Test-BoostLabCopilotSourceIntegrity
    if (-not [bool]$sourceIntegrity.Valid) {
        return New-BoostLabCopilotResult `
            -Success $false `
            -Action $ActionName `
            -Message $sourceIntegrity.Message `
            -Data ([pscustomobject]@{ SourceIntegrity = $sourceIntegrity })
    }

    $checkAdmin = if ($null -ne $AdministratorChecker) {
        $AdministratorChecker
    }
    else {
        { Test-BoostLabAdministrator }
    }
    if (-not [bool](& $checkAdmin)) {
        return New-BoostLabCopilotResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Administrator rights are required to run the approved Copilot source-equivalent workflow.'
    }

    if ([string]::IsNullOrWhiteSpace($env:SystemRoot)) {
        return New-BoostLabCopilotResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Copilot could not run because the Windows system directory is unavailable.'
    }
    $commandProcessorPath = Join-Path $env:SystemRoot 'System32\cmd.exe'
    if (-not (Test-Path -LiteralPath $commandProcessorPath -PathType Leaf)) {
        return New-BoostLabCopilotResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Copilot could not run because cmd.exe was not found.'
    }

    $stopNamedProcess = if ($null -ne $NamedProcessStopper) {
        $NamedProcessStopper
    }
    else {
        { param($Name) Stop-Process -Name $Name -Force -ErrorAction SilentlyContinue }
    }
    $stopWildcardProcess = if ($null -ne $WildcardProcessStopper) {
        $WildcardProcessStopper
    }
    else {
        {
            param($Pattern)
            Get-Process | Where-Object { $_.ProcessName -like $Pattern } | Stop-Process -Force -ErrorAction SilentlyContinue
        }
    }
    $removeAppx = if ($null -ne $AppxRemover) {
        $AppxRemover
    }
    else {
        { param($Pattern) Get-AppXPackage -AllUsers | Where-Object { $_.Name -like $Pattern } | Remove-AppxPackage -ErrorAction SilentlyContinue }
    }
    $registerAppx = if ($null -ne $AppxRegistrar) {
        $AppxRegistrar
    }
    else {
        {
            param($Pattern)
            Get-AppXPackage -AllUsers |
                Where-Object { $_.Name -like $Pattern } |
                ForEach-Object {
                    Add-AppxPackage -DisableDevelopmentMode -Register -ErrorAction SilentlyContinue "$($_.InstallLocation)\AppXManifest.xml"
                }
        }
    }
    $runRegistryCommand = if ($null -ne $RegistryCommandRunner) {
        $RegistryCommandRunner
    }
    else {
        {
            param($CommandText, $Description)
            Invoke-BoostLabCopilotRegistryCommand `
                -CommandProcessorPath $commandProcessorPath `
                -CommandText $CommandText `
                -Description $Description
        }
    }

    $operations = @(Get-BoostLabCopilotOperations -ActionName $ActionName)
    $operationStatuses = [System.Collections.Generic.List[object]]::new()
    $errors = [System.Collections.Generic.List[string]]::new()
    foreach ($operation in $operations) {
        try {
            switch ([string]$operation.Kind) {
                'StopNamedProcesses' {
                    foreach ($processName in @($operation.Targets)) {
                        & $stopNamedProcess ([string]$processName)
                    }
                }
                'StopWildcardProcesses' {
                    & $stopWildcardProcess ([string]$operation.Pattern)
                }
                'RemoveAppxPackages' {
                    & $removeAppx ([string]$operation.Pattern)
                }
                'RegisterAppxPackages' {
                    & $registerAppx ([string]$operation.Pattern)
                }
                'SetRegistryValue' {
                    & $runRegistryCommand ([string]$operation.Command) ([string]$operation.Id)
                }
                'DeleteRegistryKey' {
                    & $runRegistryCommand ([string]$operation.Command) ([string]$operation.Id)
                }
            }
            $operationStatuses.Add([pscustomobject]@{
                    Id      = [string]$operation.Id
                    Kind    = [string]$operation.Kind
                    Status  = 'Completed'
                    Message = 'Operation completed.'
                })
        }
        catch {
            $message = $_.Exception.Message
            $errors.Add($message)
            $operationStatuses.Add([pscustomobject]@{
                    Id      = [string]$operation.Id
                    Kind    = [string]$operation.Kind
                    Status  = 'Failed'
                    Message = $message
                })
        }
    }

    $verificationResult = Test-BoostLabCopilotState `
        -ActionName $ActionName `
        -RegistryReader $RegistryReader `
        -RegistryKeyReader $RegistryKeyReader `
        -ProcessReader $ProcessReader `
        -AppxReader $AppxReader
    $data = [pscustomobject]@{
        Operations = $operationStatuses.ToArray()
        CompletedAt = Get-Date
    }

    if ($errors.Count -gt 0) {
        return New-BoostLabCopilotResult `
            -Success $false `
            -Action $ActionName `
            -Message ("Copilot $ActionName completed with errors: {0}" -f ($errors -join '; ')) `
            -Data $data `
            -VerificationResult $verificationResult
    }
    if ($verificationResult.Status -eq 'Failed') {
        return New-BoostLabCopilotResult `
            -Success $false `
            -Action $ActionName `
            -Message "Copilot $ActionName verification failed." `
            -Data $data `
            -VerificationResult $verificationResult
    }

    $message = if ($ActionName -eq 'Apply') {
        'Copilot Off (Recommended) source workflow completed.'
    }
    else {
        'Copilot Default source workflow completed.'
    }
    return New-BoostLabCopilotResult `
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
        return New-BoostLabCopilotResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Unsupported action. Only Apply and Default are allowed.'
    }
    if (-not $Confirmed) {
        return New-BoostLabCopilotResult `
            -Success $false `
            -Action $ActionName `
            -Message 'Cancelled by user' `
            -Cancelled $true
    }

    return Invoke-BoostLabCopilotAction -ActionName $ActionName
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
