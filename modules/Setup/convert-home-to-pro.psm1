Set-StrictMode -Version Latest

$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$verificationModulePath = Join-Path $projectRoot 'core\Verification.psm1'
if (-not (Get-Command -Name 'New-BoostLabVerificationResult' -ErrorAction SilentlyContinue)) {
    Import-Module -Name $verificationModulePath -Scope Local -Force -ErrorAction Stop
}
$environmentModulePath = Join-Path $projectRoot 'core\Environment.psm1'
if (-not (Get-Command -Name 'Resolve-BoostLabWindowsEditionCapability' -ErrorAction SilentlyContinue)) {
    Import-Module -Name $environmentModulePath -Scope Local -Force -ErrorAction Stop
}

$script:BoostLabToolMetadata = [ordered]@{
    Id = 'convert-home-to-pro'; Title = 'Convert Home To Pro'; Stage = 'Setup'; Order = 2
    Type = 'assistant'; RiskLevel = 'high'
    Description = 'Copy the Microsoft generic Windows Pro edition-conversion key and open the Windows Activation product-key flow; activation requires a valid Pro license.'
    SourceType = 'YazanProvidedForgottenScript'
    Actions = @('Apply')
    Capabilities = [ordered]@{
        RequiresAdmin = $true; RequiresInternet = $false; CanReboot = $false
        CanModifyRegistry = $false; CanModifyServices = $false; CanInstallSoftware = $false
        CanDownload = $false; CanModifyDrivers = $false; CanModifySecurity = $true
        CanDeleteFiles = $false; UsesTrustedInstaller = $false; UsesSafeMode = $false
        SupportsDefault = $false; SupportsRestore = $false; NeedsExplicitConfirmation = $true
    }
}
$script:BoostLabImplementedActions = @('Apply')
$script:BoostLabSourceRelativePath = 'source-extra/forgotten-scripts/3 Convert Home To Pro.ps1'
$script:BoostLabExpectedSourceHash = '3B779A75960FB724A2F5FF756FCEDD1CF6897D0021FD6DBE1D671189CBA57924'
$script:BoostLabExpectedCanonicalSourceHash = '3B779A75960FB724A2F5FF756FCEDD1CF6897D0021FD6DBE1D671189CBA57924'
$script:BoostLabGenericProEditionKey = 'VK7JG-NPHTM-C97JM-9MPGT-3V66T'

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

function Get-BoostLabConvertHomeToProSourcePath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return Join-Path $projectRoot ($script:BoostLabSourceRelativePath -replace '/', '\')
}

function Get-BoostLabConvertHomeToProSourceStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $sourceVerificationModulePath = Join-Path $projectRoot 'core\SourceVerification.psm1'
    if (-not (Get-Command -Name 'Test-BoostLabSourceChecksum' -ErrorAction SilentlyContinue)) {
        Import-Module -Name $sourceVerificationModulePath -Scope Local -Force -ErrorAction Stop
    }

    $sourcePath = Get-BoostLabConvertHomeToProSourcePath
    $verification = Test-BoostLabSourceChecksum `
        -LiteralPath $sourcePath `
        -ExpectedSha256 $script:BoostLabExpectedSourceHash `
        -ExpectedCanonicalSha256 $script:BoostLabExpectedCanonicalSourceHash

    [pscustomobject]@{
        SourcePath               = $sourcePath
        SourceRelativePath       = $script:BoostLabSourceRelativePath
        SourceType               = [string]$script:BoostLabToolMetadata['SourceType']
        Exists                   = [bool]$verification.Exists
        ExpectedSha256           = $script:BoostLabExpectedSourceHash
        DetectedSha256           = [string]$verification.DetectedSha256
        ExpectedCanonicalSha256  = $script:BoostLabExpectedCanonicalSourceHash
        DetectedCanonicalSha256  = [string]$verification.DetectedCanonicalSha256
        ChecksumStatus           = [string]$verification.ChecksumStatus
        RawChecksumStatus        = [string]$verification.RawChecksumStatus
        CanonicalChecksumStatus  = [string]$verification.CanonicalChecksumStatus
        VerificationMode         = [string]$verification.VerificationMode
        TextNormalizationEnabled = [bool]$verification.TextNormalizationEnabled
    }
}

function Get-BoostLabConvertHomeToProSystemSettingsAdminFlowsPath {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    return Join-Path $env:windir 'System32\SystemSettingsAdminFlows.exe'
}

function Get-BoostLabConvertHomeToProEditionAvailability {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [scriptblock]$EditionCapabilityReader = { Resolve-BoostLabWindowsEditionCapability }
    )

    try {
        $editionResults = @(& $EditionCapabilityReader)
        $editionCapability = if ($editionResults.Count -gt 0) { $editionResults[0] } else { Resolve-BoostLabWindowsEditionCapability -WindowsVersion ([pscustomobject]@{}) }
    }
    catch {
        $editionCapability = [pscustomobject]@{
            DetectionStatus = 'Unknown'
            CurrentEdition = 'Unknown'
            DetectedWindowsEdition = 'Unknown'
            EditionFamily = 'Unknown'
            EditionCapability = 'Unknown'
            SupportsConvertHomeToPro = $false
            AvailabilityReason = "Windows edition detection failed: $($_.Exception.Message)"
        }
    }

    Get-BoostLabEditionAwareToolAvailability -ToolId 'convert-home-to-pro' -EditionCapability $editionCapability
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
        SourceType         = [string]$script:BoostLabToolMetadata['SourceType']
        Actions            = @($script:BoostLabToolMetadata['Actions'])
        Capabilities       = [pscustomobject]$script:BoostLabToolMetadata['Capabilities']
        ImplementedActions = @($script:BoostLabImplementedActions)
    }
}

function Test-BoostLabToolCompatibility {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [scriptblock]$CommandResolver = {
            param($CommandName)
            Get-Command -Name $CommandName -ErrorAction SilentlyContinue
        },

        [scriptblock]$FileExists = {
            param($LiteralPath)
            Test-Path -LiteralPath $LiteralPath -PathType Leaf
        },

        [string]$OperatingSystem = $env:OS
    )

    $missingCommands = @(
        foreach ($commandName in @('Set-Clipboard', 'Start-Process')) {
            $resolvedCommands = @(& $CommandResolver $commandName)
            if ($resolvedCommands.Count -eq 0) {
                $commandName
            }
        }
    )
    $flowPath = Get-BoostLabConvertHomeToProSystemSettingsAdminFlowsPath
    $flowExists = [bool](& $FileExists $flowPath)
    $editionAvailability = Get-BoostLabConvertHomeToProEditionAvailability
    $supported = $OperatingSystem -eq 'Windows_NT' -and $missingCommands.Count -eq 0 -and $flowExists

    [pscustomobject]@{
        Supported       = $supported
        ToolId          = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
        MissingCommands = $missingCommands
        ProductKeyFlow  = $flowPath
        EditionAvailability = $editionAvailability
        DetectedWindowsEdition = [string]$editionAvailability.DetectedWindowsEdition
        EditionFamily = [string]$editionAvailability.EditionFamily
        EditionCapability = [string]$editionAvailability.EditionCapability
        Reason          = if ($OperatingSystem -ne 'Windows_NT') {
            'Convert Home To Pro requires Windows.'
        }
        elseif ($missingCommands.Count -gt 0) {
            'Convert Home To Pro is unavailable because these commands were not found: {0}.' -f ($missingCommands -join ', ')
        }
        elseif (-not $flowExists) {
            'Convert Home To Pro is unavailable because SystemSettingsAdminFlows.exe was not found.'
        }
        else {
            'Windows Activation product-key flow is available.'
        }
        Timestamp       = Get-Date
    }
}

function Get-BoostLabToolState {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    [pscustomobject]@{
        ToolId          = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle       = [string]$script:BoostLabToolMetadata['Title']
        Status          = 'Ready'
        SourceType      = [string]$script:BoostLabToolMetadata['SourceType']
        LastAction      = $null
        LastResult      = $null
        RestartRequired = $false
        Timestamp       = Get-Date
    }
}

function Get-BoostLabConvertHomeToProSourceBehavior {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    [pscustomobject]@{
        SourceType       = [string]$script:BoostLabToolMetadata['SourceType']
        SourceOperations = @(
            'Requires Administrator through self-elevation in the original script.'
            'Displays "Disable Internet First".'
            'Copies VK7JG-NPHTM-C97JM-9MPGT-3V66T to the clipboard.'
            'Opens ms-settings:activation.'
            'Runs SystemSettingsAdminFlows.exe EnterProductKey.'
            'Pauses for user input.'
        )
        LegalBoundary = 'The copied Microsoft generic Pro key is for Windows edition conversion/setup only and does not activate Windows; a valid Windows Pro license is required for activation.'
        ForbiddenBehaviorAbsent = @(
            'No KMS host.'
            'No crack or activation bypass.'
            'No slmgr, changepk, DISM, service, driver, registry, download, installer, or reboot command.'
        )
    }
}

function New-BoostLabConvertHomeToProKeyDialog {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    [pscustomobject]@{
        Title                    = 'Convert Home To Pro'
        SourceInstructions       = @(
            'Disable Internet First'
            ('Enter: {0} (Or Paste From Clipboard)' -f $script:BoostLabGenericProEditionKey)
        )
        Message                  = ('Disable Internet first, then enter or paste {0} in the Windows product-key flow.' -f $script:BoostLabGenericProEditionKey)
        GenericProSetupKey       = $script:BoostLabGenericProEditionKey
        CopyFriendlyText         = $script:BoostLabGenericProEditionKey
        ClipboardPrepopulated    = $true
        RequiresValidProLicense  = $true
        DigitalEntitlementApplies = $true
        LegalBoundary            = 'This generic Pro setup key is for the Windows edition-conversion flow only; activation still requires a valid Windows Pro license or digital entitlement.'
        ForbiddenBehaviorAbsent  = @(
            'No KMS.'
            'No crack.'
            'No activation bypass.'
            'No slmgr, changepk, DISM, download, installer, registry, service, driver, or reboot command.'
        )
    }
}

function New-BoostLabConvertHomeToProResult {
    param(
        [Parameter(Mandatory)]
        [bool]$Success,

        [Parameter(Mandatory)]
        [string]$Action,

        [Parameter(Mandatory)]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$CommandStatus,

        [Parameter(Mandatory)]
        [string]$VerificationStatus,

        [Parameter(Mandatory)]
        [string]$Message,

        [bool]$Cancelled = $false,

        [object[]]$Warnings = @(),

        [object[]]$Errors = @(),

        [AllowNull()]
        [object]$Data = $null,

        [AllowNull()]
        [object]$VerificationResult = $null
    )

    [pscustomobject]@{
        Success            = $Success
        Status             = $Status
        ToolId             = [string]$script:BoostLabToolMetadata['Id']
        ToolTitle          = [string]$script:BoostLabToolMetadata['Title']
        Action             = $Action
        CommandStatus      = $CommandStatus
        VerificationStatus = $VerificationStatus
        Message            = $Message
        RestartRequired    = $false
        Cancelled          = $Cancelled
        Warnings           = @($Warnings)
        Errors             = @($Errors)
        Data               = $Data
        VerificationResult = $VerificationResult
        Timestamp          = Get-Date
    }
}

function New-BoostLabConvertHomeToProCommandResult {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [bool]$Success = $true,

        [string]$CommandStatus = 'Completed',

        [string]$Message = ''
    )

    [pscustomobject]@{
        Name          = $Name
        Success       = $Success
        CommandStatus = $CommandStatus
        Message       = $Message
        Timestamp     = Get-Date
    }
}

function Invoke-BoostLabConvertHomeToProCommand {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [scriptblock]$Executor
    )

    try {
        $results = @(& $Executor)
        if ($results.Count -gt 0 -and $null -ne $results[0]) {
            $raw = $results[0]
            $successProperty = $raw.PSObject.Properties['Success']
            $statusProperty = $raw.PSObject.Properties['CommandStatus']
            $messageProperty = $raw.PSObject.Properties['Message']
            return New-BoostLabConvertHomeToProCommandResult `
                -Name $Name `
                -Success $(if ($null -ne $successProperty) { [bool]$successProperty.Value } else { $true }) `
                -CommandStatus $(if ($null -ne $statusProperty) { [string]$statusProperty.Value } else { 'Completed' }) `
                -Message $(if ($null -ne $messageProperty) { [string]$messageProperty.Value } else { '' })
        }

        return New-BoostLabConvertHomeToProCommandResult -Name $Name -Message "$Name completed."
    }
    catch {
        return New-BoostLabConvertHomeToProCommandResult `
            -Name $Name `
            -Success $false `
            -CommandStatus 'Failed' `
            -Message $_.Exception.Message
    }
}

function New-BoostLabConvertHomeToProVerification {
    param(
        [Parameter(Mandatory)]
        [string]$Status,

        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter(Mandatory)]
        [object]$SourceStatus,

        [object[]]$CommandResults = @()
    )

    $checks = [System.Collections.Generic.List[object]]::new()
    $checks.Add((New-BoostLabVerificationCheck `
        -Name 'Source verification' `
        -Expected 'Passed raw or canonical source-extra SHA-256 verification' `
        -Actual ([string]$SourceStatus.ChecksumStatus) `
        -Status $(if ([string]$SourceStatus.ChecksumStatus -eq 'Passed') { 'Passed' } else { 'Failed' }) `
        -Message ('Source verification mode: {0}.' -f [string]$SourceStatus.VerificationMode)))

    foreach ($commandResult in @($CommandResults)) {
        $checks.Add((New-BoostLabVerificationCheck `
            -Name ([string]$commandResult.Name) `
            -Expected 'Completed' `
            -Actual ([string]$commandResult.CommandStatus) `
            -Status $(if ([bool]$commandResult.Success) { 'Passed' } else { 'Failed' }) `
            -Message ([string]$commandResult.Message)))
    }

    $checks.Add((New-BoostLabVerificationCheck `
        -Name 'Legal activation boundary' `
        -Expected 'Edition conversion only; no activation bypass' `
        -Actual 'Generic Pro setup key copied, activation remains license-bound' `
        -Status 'Passed' `
        -Message 'No KMS, crack, slmgr, changepk, DISM, or activation-bypass command is part of this tool.'))

    New-BoostLabVerificationResult `
        -ToolId ([string]$script:BoostLabToolMetadata['Id']) `
        -ToolTitle ([string]$script:BoostLabToolMetadata['Title']) `
        -Action 'Apply' `
        -Status $Status `
        -ExpectedState 'Generic Pro edition-conversion key copied and Windows product-key UI opened' `
        -DetectedState $Message `
        -Checks $checks.ToArray() `
        -Message $Message
}

function Invoke-BoostLabConvertHomeToProApply {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [scriptblock]$ClipboardWriter = {
            param($Value)
            Set-Clipboard -Value $Value -ErrorAction Stop
            [pscustomobject]@{ Success = $true; CommandStatus = 'Completed'; Message = 'Generic Windows Pro setup key copied to clipboard.' }
        },

        [scriptblock]$SettingsLauncher = {
            Start-Process 'ms-settings:activation' -ErrorAction Stop
            [pscustomobject]@{ Success = $true; CommandStatus = 'Completed'; Message = 'Windows Activation settings opened.' }
        },

        [scriptblock]$ProductKeyFlowLauncher = {
            $flowPath = Get-BoostLabConvertHomeToProSystemSettingsAdminFlowsPath
            & $flowPath 'EnterProductKey'
            [pscustomobject]@{ Success = $true; CommandStatus = 'Completed'; Message = 'Windows Enter product key flow opened.' }
        },

        [scriptblock]$DialogPresenter = {
            param($Dialog)
            [pscustomobject]@{
                Success       = $true
                CommandStatus = 'Completed'
                Message       = ('Convert Home To Pro source instructions prepared for Latest Result: {0}; {1}.' -f @($Dialog.SourceInstructions)[0], @($Dialog.SourceInstructions)[1])
            }
        },

        [AllowNull()]
        [object]$EditionAvailability = $null
    )

    if ($null -eq $EditionAvailability) {
        $EditionAvailability = Get-BoostLabConvertHomeToProEditionAvailability
    }

    $sourceStatus = Get-BoostLabConvertHomeToProSourceStatus
    if ([string]$sourceStatus.ChecksumStatus -ne 'Passed') {
        $verification = New-BoostLabConvertHomeToProVerification `
            -Status 'Failed' `
            -Message 'Convert Home To Pro source-extra checksum verification failed or the source file is missing.' `
            -SourceStatus $sourceStatus

        return New-BoostLabConvertHomeToProResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'SourceVerificationFailed' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'Failed' `
            -Message 'Convert Home To Pro blocked because the Yazan-provided source-extra script failed checksum verification.' `
            -Data ([pscustomobject]@{
                Source                = $sourceStatus
                ChangesExecuted       = $false
                ClipboardAttempted    = $false
                SettingsOpenAttempted = $false
                ProductKeyFlowAttempted = $false
            }) `
            -Errors @('Source-extra checksum verification failed; no edition-conversion UI action was run.') `
            -VerificationResult $verification
    }

    $commandResults = [System.Collections.Generic.List[object]]::new()
    $keyDialog = New-BoostLabConvertHomeToProKeyDialog
    $commandResults.Add((Invoke-BoostLabConvertHomeToProCommand -Name 'Show Convert Home To Pro key instructions' -Executor { & $DialogPresenter $keyDialog }))
    if ([bool]$commandResults[$commandResults.Count - 1].Success) {
        $commandResults.Add((Invoke-BoostLabConvertHomeToProCommand -Name 'Set-Clipboard generic Pro setup key' -Executor { & $ClipboardWriter $script:BoostLabGenericProEditionKey }))
    }
    if ([bool]$commandResults[$commandResults.Count - 1].Success) {
        $commandResults.Add((Invoke-BoostLabConvertHomeToProCommand -Name 'Open ms-settings:activation' -Executor $SettingsLauncher))
    }
    if ([bool]$commandResults[$commandResults.Count - 1].Success) {
        $commandResults.Add((Invoke-BoostLabConvertHomeToProCommand -Name 'Open SystemSettingsAdminFlows EnterProductKey' -Executor $ProductKeyFlowLauncher))
    }

    $failed = @($commandResults | Where-Object { -not [bool]$_.Success })
    $success = @($failed).Count -eq 0
    $verificationStatus = if ($success) { 'Passed' } else { 'Failed' }
    $message = if ($success) {
        ('Convert Home To Pro prepared the source-defined edition-conversion flow: Disable Internet first, then enter or paste {0}. A valid Windows Pro license or digital entitlement is still required for activation.' -f $script:BoostLabGenericProEditionKey)
    }
    else {
        'Convert Home To Pro stopped because a source-defined UI preparation step failed.'
    }
    $verification = New-BoostLabConvertHomeToProVerification `
        -Status $verificationStatus `
        -Message $message `
        -SourceStatus $sourceStatus `
        -CommandResults $commandResults.ToArray()

    return New-BoostLabConvertHomeToProResult `
        -Success $success `
        -Action 'Apply' `
        -Status $(if ($success) { 'Completed' } else { 'CommandFailed' }) `
        -CommandStatus $(if ($success) { 'Completed' } else { 'Failed' }) `
        -VerificationStatus $verificationStatus `
        -Message $message `
        -Warnings @(
            'Disable internet first, matching the Yazan-provided source prompt.'
            'The generic Windows Pro setup key does not activate Windows; activation requires a valid Windows Pro license.'
        ) `
        -Errors @($failed | ForEach-Object { [string]$_.Message }) `
        -Data ([pscustomobject]@{
            Source                  = $sourceStatus
            DetectedWindowsEdition  = [string]$EditionAvailability.DetectedWindowsEdition
            CurrentEdition          = [string]$EditionAvailability.CurrentEdition
            EditionFamily           = [string]$EditionAvailability.EditionFamily
            EditionCapability       = [string]$EditionAvailability.EditionCapability
            AvailabilityReason      = [string]$EditionAvailability.AvailabilityReason
            RequiredEdition         = [string]$EditionAvailability.RequiredEdition
            RuntimeGuardResult      = [string]$EditionAvailability.RuntimeGuardResult
            SourceBehavior          = Get-BoostLabConvertHomeToProSourceBehavior
            UserDialog              = $keyDialog
            GenericProSetupKey      = $script:BoostLabGenericProEditionKey
            RequiresValidProLicense = $true
            ChangesExecuted         = $success
            DialogAttempted         = @($commandResults | Where-Object { [string]$_.Name -eq 'Show Convert Home To Pro key instructions' }).Count -gt 0
            ClipboardAttempted      = @($commandResults | Where-Object { [string]$_.Name -eq 'Set-Clipboard generic Pro setup key' }).Count -gt 0
            SettingsOpenAttempted   = @($commandResults | Where-Object { [string]$_.Name -eq 'Open ms-settings:activation' }).Count -gt 0
            ProductKeyFlowAttempted = @($commandResults | Where-Object { [string]$_.Name -eq 'Open SystemSettingsAdminFlows EnterProductKey' }).Count -gt 0
            Commands                = $commandResults.ToArray()
        }) `
        -VerificationResult $verification
}

function Invoke-BoostLabToolAction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)]
        [string]$ActionName,

        [bool]$Confirmed = $false,

        [scriptblock]$AdministratorDetector = { Test-BoostLabAdministrator },

        [scriptblock]$ClipboardWriter,

        [scriptblock]$SettingsLauncher,

        [scriptblock]$ProductKeyFlowLauncher,

        [scriptblock]$DialogPresenter,

        [scriptblock]$EditionCapabilityReader = { Resolve-BoostLabWindowsEditionCapability }
    )

    if ($ActionName -notin @($script:BoostLabImplementedActions)) {
        return New-BoostLabConvertHomeToProResult `
            -Success $false `
            -Action $ActionName `
            -Status 'UnsupportedAction' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Unsupported action. Convert Home To Pro exposes only Apply.' `
            -Errors @("Unsupported Convert Home To Pro action: $ActionName")
    }

    $editionAvailability = Get-BoostLabConvertHomeToProEditionAvailability -EditionCapabilityReader $EditionCapabilityReader
    if (-not [bool]$editionAvailability.IsRunnable) {
        $runtimeGuardResult = [string]$editionAvailability.RuntimeGuardResult
        $isAlreadyPro = $runtimeGuardResult -eq 'AlreadyProOrHigher'
        $message = if ($isAlreadyPro) {
            'Convert Home To Pro is not applicable because this Windows edition is already Pro or higher. No clipboard, Activation settings, product-key, edition-change, activation, or external command flow occurred.'
        }
        else {
            'Convert Home To Pro is unavailable because BoostLab could not confirm this is a Windows Home/Core edition. No clipboard, Activation settings, product-key, edition-change, activation, or external command flow occurred.'
        }

        return New-BoostLabConvertHomeToProResult `
            -Success:$isAlreadyPro `
            -Action 'Apply' `
            -Status 'NotApplicable' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message $message `
            -Warnings $(if ($isAlreadyPro) { @('AlreadyProOrHigher') } else { @() }) `
            -Errors $(if ($isAlreadyPro) { @() } else { @('EditionUnknown') }) `
            -Data ([pscustomobject]@{
                DetectedWindowsEdition   = [string]$editionAvailability.DetectedWindowsEdition
                CurrentEdition           = [string]$editionAvailability.CurrentEdition
                EditionFamily            = [string]$editionAvailability.EditionFamily
                EditionCapability        = [string]$editionAvailability.EditionCapability
                AvailabilityReason       = [string]$editionAvailability.AvailabilityReason
                RequiredEdition          = [string]$editionAvailability.RequiredEdition
                RuntimeGuardResult       = $runtimeGuardResult
                ChangesExecuted          = $false
                DialogAttempted          = $false
                ClipboardAttempted       = $false
                SettingsOpenAttempted    = $false
                ProductKeyFlowAttempted  = $false
                RequiresValidProLicense  = $true
                NoActivationBypass       = $true
            })
    }
    if (-not $Confirmed) {
        return New-BoostLabConvertHomeToProResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'Cancelled' `
            -CommandStatus 'Cancelled before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Convert Home To Pro was cancelled. No clipboard, Activation settings, product-key, edition-change, activation, or external command flow occurred.' `
            -Cancelled $true
    }
    if (-not [bool](& $AdministratorDetector)) {
        return New-BoostLabConvertHomeToProResult `
            -Success $false `
            -Action 'Apply' `
            -Status 'NeedsAdministrator' `
            -CommandStatus 'Blocked before execution' `
            -VerificationStatus 'NotApplicable' `
            -Message 'Convert Home To Pro requires Administrator rights before opening the Windows product-key flow.' `
            -Errors @('Administrator rights are required; no source-defined action was run.')
    }

    $applyParameters = @{}
    if ($PSBoundParameters.ContainsKey('ClipboardWriter')) {
        $applyParameters['ClipboardWriter'] = $ClipboardWriter
    }
    if ($PSBoundParameters.ContainsKey('SettingsLauncher')) {
        $applyParameters['SettingsLauncher'] = $SettingsLauncher
    }
    if ($PSBoundParameters.ContainsKey('ProductKeyFlowLauncher')) {
        $applyParameters['ProductKeyFlowLauncher'] = $ProductKeyFlowLauncher
    }
    if ($PSBoundParameters.ContainsKey('DialogPresenter')) {
        $applyParameters['DialogPresenter'] = $DialogPresenter
    }
    $applyParameters['EditionAvailability'] = $editionAvailability

    return Invoke-BoostLabConvertHomeToProApply @applyParameters
}

function Restore-BoostLabToolDefault {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [bool]$Confirmed = $false
    )

    return New-BoostLabConvertHomeToProResult `
        -Success $false `
        -Action 'Default' `
        -Status 'UnsupportedAction' `
        -CommandStatus 'Blocked before execution' `
        -VerificationStatus 'NotApplicable' `
        -Message 'Convert Home To Pro has no source-defined Default behavior.'
}

Export-ModuleMember -Function @(
    'Get-BoostLabToolInfo'
    'Test-BoostLabToolCompatibility'
    'Get-BoostLabToolState'
    'Invoke-BoostLabToolAction'
    'Restore-BoostLabToolDefault'
    'Get-BoostLabConvertHomeToProSourceStatus'
    'Get-BoostLabConvertHomeToProSourceBehavior'
)
