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
        [object]$VerificationResult = $null,

        [string]$Status = '',

        [string]$CommandStatus = '',

        [string]$VerificationStatus = ''
    )

    $resolvedVerificationStatus = if (-not [string]::IsNullOrWhiteSpace($VerificationStatus)) {
        $VerificationStatus
    }
    elseif ($null -ne $VerificationResult -and $null -ne $VerificationResult.PSObject.Properties['Status']) {
        [string]$VerificationResult.Status
    }
    else {
        'NotAvailable'
    }
    $resolvedStatus = if (-not [string]::IsNullOrWhiteSpace($Status)) {
        $Status
    }
    elseif ($Cancelled) {
        'Cancelled'
    }
    elseif ($Success -and $resolvedVerificationStatus -eq 'Warning') {
        'Warning'
    }
    elseif ($Success) {
        'Success'
    }
    else {
        'Error'
    }
    $resolvedCommandStatus = if (-not [string]::IsNullOrWhiteSpace($CommandStatus)) {
        $CommandStatus
    }
    elseif ($Success -and $resolvedVerificationStatus -eq 'Warning') {
        'CompletedWithWarnings'
    }
    elseif ($Success) {
        'Completed'
    }
    else {
        'Failed'
    }

    return [pscustomobject]@{
        Success            = $Success
        ToolId             = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle          = [string]$script:BoostLabToolMetadata['Title']
        Action             = $Action
        Status             = $resolvedStatus
        CommandStatus      = $resolvedCommandStatus
        VerificationStatus = $resolvedVerificationStatus
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
            Count         = @($matches).Count
            DisplayValue  = [string]@($matches).Count
            Message       = if (@($matches).Count -eq 0) { 'No matching processes detected.' } else { "$(@($matches).Count) matching process(es) detected." }
            Processes     = @($matches | ForEach-Object {
                    [pscustomobject]@{
                        ProcessName = [string]$_.ProcessName
                        Id          = if ($null -ne $_.Id) { [int]$_.Id } else { $null }
                    }
                })
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

function ConvertTo-BoostLabCopilotProcessRecord {
    param(
        [Parameter(Mandatory)]
        [object]$Process
    )

    $name = if ($null -ne $Process.PSObject.Properties['ProcessName']) {
        [string]$Process.ProcessName
    }
    elseif ($null -ne $Process.PSObject.Properties['Name']) {
        [string]$Process.Name
    }
    else {
        ''
    }

    $id = if ($null -ne $Process.PSObject.Properties['Id'] -and $null -ne $Process.Id) {
        [int]$Process.Id
    }
    else {
        $null
    }

    [pscustomobject]@{
        ProcessName = $name
        Id          = $id
    }
}

function ConvertTo-BoostLabCopilotProcessState {
    param(
        [AllowNull()]
        [object]$State
    )

    if ($null -eq $State) {
        return [pscustomobject]@{
            ReadSucceeded = $true
            Count         = 0
            DisplayValue  = '0'
            Message       = 'No matching processes detected.'
            Processes     = @()
        }
    }

    $isStructuredState = $null -ne $State.PSObject.Properties['ReadSucceeded']
    if ($isStructuredState) {
        $processes = if ($null -ne $State.PSObject.Properties['Processes']) {
            @($State.Processes)
        }
        elseif ($null -ne $State.PSObject.Properties['Matches']) {
            @($State.Matches)
        }
        else {
            @()
        }
        $count = if ($null -ne $State.PSObject.Properties['Count'] -and $null -ne $State.Count) {
            [int]$State.Count
        }
        else {
            @($processes).Count
        }
        return [pscustomobject]@{
            ReadSucceeded = [bool]$State.ReadSucceeded
            Count         = $count
            DisplayValue  = if ($null -ne $State.PSObject.Properties['DisplayValue']) { [string]$State.DisplayValue } else { [string]$count }
            Message       = if ($null -ne $State.PSObject.Properties['Message']) { [string]$State.Message } elseif ($count -eq 0) { 'No matching processes detected.' } else { "$count matching process(es) detected." }
            Processes     = @($processes | ForEach-Object {
                    if ($null -ne $_) { ConvertTo-BoostLabCopilotProcessRecord -Process $_ }
                })
        }
    }

    $matches = @($State)
    return [pscustomobject]@{
        ReadSucceeded = $true
        Count         = $matches.Count
        DisplayValue  = [string]$matches.Count
        Message       = if ($matches.Count -eq 0) { 'No matching processes detected.' } else { "$($matches.Count) matching process(es) detected: $((@($matches | ForEach-Object { (ConvertTo-BoostLabCopilotProcessRecord -Process $_).ProcessName }) | Where-Object { $_ }) -join ', ')." }
        Processes     = @($matches | ForEach-Object { ConvertTo-BoostLabCopilotProcessRecord -Process $_ })
    }
}

function ConvertTo-BoostLabCopilotPackageRecord {
    param(
        [Parameter(Mandatory)]
        [object]$Package
    )

    [pscustomobject]@{
        Name              = if ($null -ne $Package.PSObject.Properties['Name']) { [string]$Package.Name } else { '' }
        PackageFullName   = if ($null -ne $Package.PSObject.Properties['PackageFullName']) { [string]$Package.PackageFullName } else { '' }
        PackageFamilyName = if ($null -ne $Package.PSObject.Properties['PackageFamilyName']) { [string]$Package.PackageFamilyName } else { '' }
        InstallLocation   = if ($null -ne $Package.PSObject.Properties['InstallLocation']) { [string]$Package.InstallLocation } else { '' }
        User              = if ($null -ne $Package.PSObject.Properties['User']) { [string]$Package.User } elseif ($null -ne $Package.PSObject.Properties['UserSid']) { [string]$Package.UserSid } else { '' }
        Scope             = 'AllUsersInstalled'
    }
}

function Get-BoostLabCopilotPackageMatches {
    param(
        [Parameter(Mandatory)]
        [string]$Pattern
    )

    $errors = [System.Collections.Generic.List[string]]::new()
    $currentUserPackages = @()
    $allUsersPackages = @()
    $provisionedPackages = @()

    try {
        $currentUserPackages = @(Get-AppxPackage | Where-Object { $_.Name -like $Pattern })
    }
    catch {
        $errors.Add("Current-user AppX query failed: $($_.Exception.Message)")
    }

    try {
        $allUsersPackages = @(Get-AppxPackage -AllUsers | Where-Object { $_.Name -like $Pattern })
    }
    catch {
        $errors.Add("All-users AppX query failed: $($_.Exception.Message)")
    }

    try {
        if ($null -ne (Get-Command -Name 'Get-AppxProvisionedPackage' -ErrorAction SilentlyContinue)) {
            $provisionedPackages = @(
                Get-AppxProvisionedPackage -Online |
                    Where-Object { $_.DisplayName -like $Pattern -or $_.PackageName -like $Pattern }
            )
        }
    }
    catch {
        $errors.Add("Provisioned AppX query failed: $($_.Exception.Message)")
    }

    $currentUserRecords = @($currentUserPackages | ForEach-Object { ConvertTo-BoostLabCopilotPackageRecord -Package $_ })
    $allUsersRecords = @($allUsersPackages | ForEach-Object { ConvertTo-BoostLabCopilotPackageRecord -Package $_ })
    $readSucceeded = $errors.Count -eq 0

    return [pscustomobject]@{
        ReadSucceeded       = $readSucceeded
        Count               = $allUsersRecords.Count
        DisplayValue        = if ($readSucceeded) { [string]$allUsersRecords.Count } else { 'Unknown' }
        Message             = if ($errors.Count -gt 0) {
            'Copilot AppX state query completed with warning(s): {0}' -f ($errors -join '; ')
        }
        elseif ($allUsersRecords.Count -eq 0) {
            'No matching AppX packages detected.'
        }
        else {
            "$($allUsersRecords.Count) all-users matching AppX package(s) detected: $((@($allUsersRecords | ForEach-Object { if ($_.PackageFullName) { $_.PackageFullName } else { $_.Name } }) | Where-Object { $_ }) -join '; ')."
        }
        Packages            = $allUsersRecords
        AllUsersPackages    = $allUsersRecords
        CurrentUserPackages = $currentUserRecords
        ProvisionedPackages = @($provisionedPackages)
    }
}

function ConvertTo-BoostLabCopilotPackageState {
    param(
        [AllowNull()]
        [object]$State
    )

    if ($null -eq $State) {
        return [pscustomobject]@{
            ReadSucceeded      = $true
            Count              = 0
            DisplayValue       = '0'
            Message            = 'No matching AppX packages detected.'
            Packages           = @()
            AllUsersPackages    = @()
            CurrentUserPackages = @()
            ProvisionedPackages = @()
        }
    }

    $isStructuredState = $null -ne $State.PSObject.Properties['ReadSucceeded']
    if ($isStructuredState) {
        $packages = if ($null -ne $State.PSObject.Properties['Packages']) {
            @($State.Packages)
        }
        elseif ($null -ne $State.PSObject.Properties['Matches']) {
            @($State.Matches)
        }
        else {
            @()
        }
        $packageRecords = @($packages | ForEach-Object {
                if ($null -ne $_) { ConvertTo-BoostLabCopilotPackageRecord -Package $_ }
            })
        $currentUserRecords = if ($null -ne $State.PSObject.Properties['CurrentUserPackages']) {
            @($State.CurrentUserPackages | ForEach-Object {
                    if ($null -ne $_) { ConvertTo-BoostLabCopilotPackageRecord -Package $_ }
                })
        }
        else {
            @()
        }
        $allUsersRecords = if ($null -ne $State.PSObject.Properties['AllUsersPackages']) {
            @($State.AllUsersPackages | ForEach-Object {
                    if ($null -ne $_) { ConvertTo-BoostLabCopilotPackageRecord -Package $_ }
                })
        }
        else {
            $packageRecords
        }
        $count = if ($null -ne $State.PSObject.Properties['Count'] -and $null -ne $State.Count) {
            [int]$State.Count
        }
        else {
            $packageRecords.Count
        }
        return [pscustomobject]@{
            ReadSucceeded      = [bool]$State.ReadSucceeded
            Count              = $count
            DisplayValue       = if ($null -ne $State.PSObject.Properties['DisplayValue']) { [string]$State.DisplayValue } else { [string]$count }
            Message            = if ($null -ne $State.PSObject.Properties['Message']) { [string]$State.Message } elseif ($count -eq 0) { 'No matching AppX packages detected.' } else { "$count matching AppX package(s) detected." }
            Packages           = $packageRecords
            AllUsersPackages    = $allUsersRecords
            CurrentUserPackages = $currentUserRecords
            ProvisionedPackages = if ($null -ne $State.PSObject.Properties['ProvisionedPackages']) { @($State.ProvisionedPackages) } else { @() }
        }
    }

    $packages = @($State)
    $packageRecords = @($packages | ForEach-Object { ConvertTo-BoostLabCopilotPackageRecord -Package $_ })
    return [pscustomobject]@{
        ReadSucceeded      = $true
        Count              = $packageRecords.Count
        DisplayValue       = [string]$packageRecords.Count
        Message            = if ($packageRecords.Count -eq 0) { 'No matching AppX packages detected.' } else { "$($packageRecords.Count) matching AppX package(s) detected: $((@($packageRecords | ForEach-Object { if ($_.PackageFullName) { $_.PackageFullName } else { $_.Name } }) | Where-Object { $_ }) -join '; ')." }
        Packages           = $packageRecords
        AllUsersPackages    = $packageRecords
        CurrentUserPackages = @()
        ProvisionedPackages = @()
    }
}

function Get-BoostLabCopilotAppxRemovalOutcome {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [AllowNull()]
        [object]$ErrorRecord
    )

    $messages = [System.Collections.Generic.List[string]]::new()
    if ($null -eq $ErrorRecord) {
        $messages.Add('')
    }
    elseif ($ErrorRecord -is [System.Management.Automation.ErrorRecord]) {
        $messages.Add([string]$ErrorRecord.Exception.Message)
        if ($null -ne $ErrorRecord.Exception.InnerException) {
            $messages.Add([string]$ErrorRecord.Exception.InnerException.Message)
        }
        if (-not [string]::IsNullOrWhiteSpace([string]$ErrorRecord.FullyQualifiedErrorId)) {
            $messages.Add([string]$ErrorRecord.FullyQualifiedErrorId)
        }
    }
    elseif ($ErrorRecord -is [System.Exception]) {
        $messages.Add([string]$ErrorRecord.Message)
        if ($null -ne $ErrorRecord.InnerException) {
            $messages.Add([string]$ErrorRecord.InnerException.Message)
        }
    }
    else {
        $messages.Add([string]$ErrorRecord)
    }

    $messageText = ($messages.ToArray() -join "`n")
    if (
        $messageText -like '*0x80073CFA*' -or
        $messageText -like '*0x80070032*' -or
        $messageText -like '*part of Windows and cannot be uninstalled*'
    ) {
        return [pscustomobject]@{
            Outcome = 'SkippedProtectedSystemApp'
            IsFailure = $false
            Reason = $messageText
        }
    }

    if (
        $messageText -like '*0x80073CF3*' -or
        $messageText -like '*dependency*' -or
        $messageText -like '*conflict validation*' -or
        $messageText -like '*dependent package*'
    ) {
        return [pscustomobject]@{
            Outcome = 'SkippedDependencyFramework'
            IsFailure = $false
            Reason = $messageText
        }
    }

    [pscustomobject]@{
        Outcome = 'FailedUnexpected'
        IsFailure = $true
        Reason = $messageText
    }
}

function Test-BoostLabCopilotPackageRecordMatch {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [AllowNull()]
        [object]$Left,

        [AllowNull()]
        [object]$Right
    )

    if ($null -eq $Left -or $null -eq $Right) {
        return $false
    }

    $leftRecord = ConvertTo-BoostLabCopilotPackageRecord -Package $Left
    $rightRecord = ConvertTo-BoostLabCopilotPackageRecord -Package $Right
    if (
        -not [string]::IsNullOrWhiteSpace($leftRecord.PackageFullName) -and
        -not [string]::IsNullOrWhiteSpace($rightRecord.PackageFullName)
    ) {
        return [string]$leftRecord.PackageFullName -eq [string]$rightRecord.PackageFullName
    }

    if (
        -not [string]::IsNullOrWhiteSpace($leftRecord.PackageFamilyName) -and
        -not [string]::IsNullOrWhiteSpace($rightRecord.PackageFamilyName)
    ) {
        return [string]$leftRecord.PackageFamilyName -eq [string]$rightRecord.PackageFamilyName
    }

    return (
        -not [string]::IsNullOrWhiteSpace($leftRecord.Name) -and
        [string]$leftRecord.Name -eq [string]$rightRecord.Name
    )
}

function Invoke-BoostLabCopilotDefaultAppxRemove {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Package
    )

    $record = ConvertTo-BoostLabCopilotPackageRecord -Package $Package
    if (-not [string]::IsNullOrWhiteSpace($record.PackageFullName)) {
        try {
            Remove-AppxPackage `
                -Package ([string]$record.PackageFullName) `
                -AllUsers `
                -ErrorAction Stop `
                -WarningAction SilentlyContinue `
                -InformationAction SilentlyContinue | Out-Null
            return
        }
        catch [System.Management.Automation.ParameterBindingException] {
            $Package | Remove-AppxPackage -ErrorAction Stop -WarningAction SilentlyContinue -InformationAction SilentlyContinue | Out-Null
            return
        }
    }

    $Package | Remove-AppxPackage -ErrorAction Stop -WarningAction SilentlyContinue -InformationAction SilentlyContinue | Out-Null
}

function Invoke-BoostLabCopilotRemoveAppxPackages {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$Pattern,

        [AllowNull()]
        [object]$PreRemovalState = $null,

        [AllowNull()]
        [scriptblock]$AppxRemover = $null
    )

    $preState = ConvertTo-BoostLabCopilotPackageState -State $PreRemovalState
    $packages = @($preState.Packages)
    $outcomes = [System.Collections.Generic.List[object]]::new()
    $removed = [System.Collections.Generic.List[object]]::new()
    $protectedSkipped = [System.Collections.Generic.List[object]]::new()
    $dependencySkipped = [System.Collections.Generic.List[object]]::new()
    $failed = [System.Collections.Generic.List[object]]::new()

    if ($packages.Count -eq 0) {
        $outcomes.Add([pscustomobject]@{
            Outcome = 'AlreadyAbsent'
            Package = $null
            Reason = 'No installed AppX package matched the source *Copilot* pattern before removal.'
        })
    }

    foreach ($package in $packages) {
        $record = ConvertTo-BoostLabCopilotPackageRecord -Package $package
        try {
            if ($null -ne $AppxRemover) {
                & $AppxRemover $package $Pattern | Out-Null
            }
            else {
                Invoke-BoostLabCopilotDefaultAppxRemove -Package $package
            }

            $item = [pscustomobject]@{
                Outcome = 'Removed'
                Package = $record
                Reason = 'Remove-AppxPackage completed for the source-matching Copilot package.'
            }
            $removed.Add($item)
            $outcomes.Add($item)
        }
        catch {
            $classification = Get-BoostLabCopilotAppxRemovalOutcome -ErrorRecord $_
            $item = [pscustomobject]@{
                Outcome = [string]$classification.Outcome
                Package = $record
                Reason = [string]$classification.Reason
            }

            if ([string]$classification.Outcome -eq 'SkippedProtectedSystemApp') {
                $protectedSkipped.Add($item)
                $outcomes.Add($item)
                continue
            }
            if ([string]$classification.Outcome -eq 'SkippedDependencyFramework') {
                $dependencySkipped.Add($item)
                $outcomes.Add($item)
                continue
            }

            $failed.Add($item)
            $outcomes.Add($item)
        }
    }

    $success = ($failed.Count -eq 0)
    [pscustomobject]@{
        Success = $success
        Message = if ($success) {
            "Processed $($packages.Count) source-matching Copilot AppX package(s); removed $($removed.Count); protected system skipped $($protectedSkipped.Count); dependency/framework skipped $($dependencySkipped.Count); unexpected failures $($failed.Count)."
        }
        else {
            "Failed to remove $($failed.Count) source-matching Copilot AppX package(s); removed $($removed.Count); protected system skipped $($protectedSkipped.Count); dependency/framework skipped $($dependencySkipped.Count)."
        }
        Pattern = $Pattern
        PreRemovalPackages = $packages
        RemovedPackages = $removed.ToArray()
        ProtectedSystemAppSkippedPackages = $protectedSkipped.ToArray()
        DependencyFrameworkSkippedPackages = $dependencySkipped.ToArray()
        FailedPackages = $failed.ToArray()
        PackageOutcomes = $outcomes.ToArray()
    }
}

function Add-BoostLabCopilotRemainingPackageOutcomes {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [object[]]$RemovalOutcomes = @(),

        [object[]]$RemainingPackages = @()
    )

    $combined = [System.Collections.Generic.List[object]]::new()
    foreach ($outcome in @($RemovalOutcomes)) {
        if ($null -ne $outcome) {
            $combined.Add($outcome)
        }
    }

    foreach ($remaining in @($RemainingPackages)) {
        $isKnownSkip = @($combined | Where-Object {
            [string]$_.Outcome -in @('SkippedProtectedSystemApp', 'SkippedDependencyFramework') -and
            (Test-BoostLabCopilotPackageRecordMatch -Left $_.Package -Right $remaining)
        }).Count -gt 0
        $alreadyMarkedRemaining = @($combined | Where-Object {
            [string]$_.Outcome -eq 'RemainingAfterSourceRemove' -and
            (Test-BoostLabCopilotPackageRecordMatch -Left $_.Package -Right $remaining)
        }).Count -gt 0

        if (-not $isKnownSkip -and -not $alreadyMarkedRemaining) {
            $combined.Add([pscustomobject]@{
                Outcome = 'RemainingAfterSourceRemove'
                Package = ConvertTo-BoostLabCopilotPackageRecord -Package $remaining
                Reason = 'Package still exists after source-style AppX removal and has no known protected/dependency explanation.'
            })
        }
    }

    $combined.ToArray()
}

function Test-BoostLabCopilotRemainingPackagesExplained {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [object[]]$RemainingPackages = @(),

        [object[]]$RemovalOutcomes = @()
    )

    foreach ($remaining in @($RemainingPackages)) {
        $matched = @($RemovalOutcomes | Where-Object {
            [string]$_.Outcome -in @('SkippedProtectedSystemApp', 'SkippedDependencyFramework') -and
            (Test-BoostLabCopilotPackageRecordMatch -Left $_.Package -Right $remaining)
        })
        if ($matched.Count -eq 0) {
            return $false
        }
    }

    return $true
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
        [scriptblock]$AppxReader = $null,

        [object[]]$AppxRemovalOutcomes = @()
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
            $state = ConvertTo-BoostLabCopilotProcessState -State (& $readProcess $processName '')
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

        $wildcardState = ConvertTo-BoostLabCopilotProcessState -State (& $readProcess '' $script:BoostLabCopilotWildcardProcessPattern)
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

        $appxState = ConvertTo-BoostLabCopilotPackageState -State (& $readAppx $script:BoostLabCopilotPackagePattern)
        $appxStatus = if (-not [bool]$appxState.ReadSucceeded) {
            'Warning'
        }
        elseif ([int]$appxState.Count -gt 0) {
            if (Test-BoostLabCopilotRemainingPackagesExplained -RemainingPackages @($appxState.Packages) -RemovalOutcomes @($AppxRemovalOutcomes)) {
                'Warning'
            }
            else {
                'Failed'
            }
        }
        else {
            'Passed'
        }
        $appxMessage = if ($appxStatus -eq 'Warning' -and [int]$appxState.Count -gt 0) {
            'Matching Copilot package(s) remain, but Windows reported the removal as protected/non-removable or dependency/framework blocked.'
        }
        else {
            [string]$appxState.Message
        }
        $checks.Add(
            (New-BoostLabVerificationCheck `
                -Name 'Copilot AppX package state' `
                -Expected 'No *Copilot* packages' `
                -Actual ([string]$appxState.DisplayValue) `
                -Status $appxStatus `
                -Message $appxMessage)
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

        $appxState = ConvertTo-BoostLabCopilotPackageState -State (& $readAppx $script:BoostLabCopilotPackagePattern)
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
            RemainingAppxPackages = if ($ActionName -eq 'Apply' -and $null -ne $appxState) { @($appxState.Packages) } else { @() }
            RemainingAllUsersCopilotPackages = if ($ActionName -eq 'Apply' -and $null -ne $appxState) { @($appxState.AllUsersPackages) } else { @() }
            RemainingCurrentUserCopilotPackages = if ($ActionName -eq 'Apply' -and $null -ne $appxState) { @($appxState.CurrentUserPackages) } else { @() }
            RemainingProvisionedCopilotPackages = if ($ActionName -eq 'Apply' -and $null -ne $appxState) { @($appxState.ProvisionedPackages) } else { @() }
            AppxRemovalOutcomes = if ($ActionName -eq 'Apply') { @($AppxRemovalOutcomes) } else { @() }
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
    $readAppxSnapshot = if ($null -ne $AppxReader) {
        $AppxReader
    }
    else {
        { param($Pattern) Get-BoostLabCopilotPackageMatches -Pattern $Pattern }
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
    $appxRemovalResult = $null
    $preRemovalPackageState = if ($ActionName -eq 'Apply') {
        ConvertTo-BoostLabCopilotPackageState -State (& $readAppxSnapshot $script:BoostLabCopilotPackagePattern)
    }
    else {
        $null
    }
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
                    $appxRemovalResult = Invoke-BoostLabCopilotRemoveAppxPackages `
                        -Pattern ([string]$operation.Pattern) `
                        -PreRemovalState $preRemovalPackageState `
                        -AppxRemover $AppxRemover
                    if (-not [bool]$appxRemovalResult.Success) {
                        throw [string]$appxRemovalResult.Message
                    }
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
                    Status  = if ([string]$operation.Kind -eq 'RemoveAppxPackages' -and $null -ne $appxRemovalResult -and (@($appxRemovalResult.ProtectedSystemAppSkippedPackages).Count -gt 0 -or @($appxRemovalResult.DependencyFrameworkSkippedPackages).Count -gt 0)) { 'CompletedWithWarnings' } else { 'Completed' }
                    Message = if ([string]$operation.Kind -eq 'RemoveAppxPackages' -and $null -ne $appxRemovalResult) { [string]$appxRemovalResult.Message } else { 'Operation completed.' }
                    Data    = if ([string]$operation.Kind -eq 'RemoveAppxPackages') { $appxRemovalResult } else { $null }
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

    $postRemovalPackageState = if ($ActionName -eq 'Apply') {
        ConvertTo-BoostLabCopilotPackageState -State (& $readAppxSnapshot $script:BoostLabCopilotPackagePattern)
    }
    else {
        $null
    }
    $appxRemovalOutcomes = if ($ActionName -eq 'Apply' -and $null -ne $appxRemovalResult) {
        Add-BoostLabCopilotRemainingPackageOutcomes `
            -RemovalOutcomes @($appxRemovalResult.PackageOutcomes) `
            -RemainingPackages @($postRemovalPackageState.Packages)
    }
    elseif ($ActionName -eq 'Apply') {
        Add-BoostLabCopilotRemainingPackageOutcomes `
            -RemovalOutcomes @() `
            -RemainingPackages @($postRemovalPackageState.Packages)
    }
    else {
        @()
    }
    $verificationAppxReader = if ($ActionName -eq 'Apply') {
        { param($Pattern) $null = $Pattern; $postRemovalPackageState }.GetNewClosure()
    }
    else {
        $AppxReader
    }

    $verificationResult = Test-BoostLabCopilotState `
        -ActionName $ActionName `
        -RegistryReader $RegistryReader `
        -RegistryKeyReader $RegistryKeyReader `
        -ProcessReader $ProcessReader `
        -AppxReader $verificationAppxReader `
        -AppxRemovalOutcomes @($appxRemovalOutcomes)
    $remainingPackages = @($verificationResult.DetectedState.RemainingAppxPackages)
    $remainingProvisionedPackages = @($verificationResult.DetectedState.RemainingProvisionedCopilotPackages)
    $data = [pscustomobject]@{
        Operations                          = $operationStatuses.ToArray()
        PreRemovalCopilotPackages           = if ($null -ne $preRemovalPackageState) { @($preRemovalPackageState.Packages) } else { @() }
        PreRemovalAllUsersCopilotPackages   = if ($null -ne $preRemovalPackageState) { @($preRemovalPackageState.AllUsersPackages) } else { @() }
        PreRemovalCurrentUserCopilotPackages = if ($null -ne $preRemovalPackageState) { @($preRemovalPackageState.CurrentUserPackages) } else { @() }
        PostRemovalCopilotPackages          = $remainingPackages
        PostRemovalAllUsersCopilotPackages  = if ($null -ne $postRemovalPackageState) { @($postRemovalPackageState.AllUsersPackages) } else { @() }
        PostRemovalCurrentUserCopilotPackages = if ($null -ne $postRemovalPackageState) { @($postRemovalPackageState.CurrentUserPackages) } else { @() }
        RemainingCopilotPackages            = $remainingPackages
        RemainingProvisionedCopilotPackages = $remainingProvisionedPackages
        AppxRemoval                         = $appxRemovalResult
        AppxRemovalOutcomes                 = @($appxRemovalOutcomes)
        ProvisionedPackageScope             = 'NotApplicable: Ultimate Copilot source removes installed Get-AppxPackage -AllUsers matches only.'
        CompletedAt                         = Get-Date
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
        $remainingPackageSummary = @($remainingPackages | ForEach-Object {
                $identity = if (-not [string]::IsNullOrWhiteSpace([string]$_.PackageFullName)) { [string]$_.PackageFullName } elseif (-not [string]::IsNullOrWhiteSpace([string]$_.Name)) { [string]$_.Name } else { 'UnknownPackage' }
                $family = if (-not [string]::IsNullOrWhiteSpace([string]$_.PackageFamilyName)) { " family=$($_.PackageFamilyName)" } else { '' }
                "$identity$family"
            })
        $failureMessage = "Copilot $ActionName verification failed."
        if ($remainingPackageSummary.Count -gt 0) {
            $failureMessage = "$failureMessage Remaining Copilot package(s): $($remainingPackageSummary -join '; ')."
        }
        return New-BoostLabCopilotResult `
            -Success $false `
            -Action $ActionName `
            -Message $failureMessage `
            -Data $data `
            -VerificationResult $verificationResult
    }

    if ($ActionName -eq 'Apply' -and [string]$verificationResult.Status -eq 'Warning' -and @($remainingPackages).Count -gt 0) {
        return New-BoostLabCopilotResult `
            -Success $true `
            -Action $ActionName `
            -Status 'Warning' `
            -CommandStatus 'CompletedWithWarnings' `
            -VerificationStatus 'Warning' `
            -Message 'Copilot policy disabled successfully. Copilot package remains because Windows reported it as protected/non-removable or dependency/framework blocked.' `
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
